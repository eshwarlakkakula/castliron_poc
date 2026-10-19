#!/usr/bin/env python3
"""Automated pass/fail evidence for the four POC objectives (02-POC
document, Section 5 "Success Criteria and Exit").

This has NOT been run against a real environment - it cannot be, from an
environment with no AWS/Databricks/Snowflake credentials. Every query and
API call below uses well-known, documented client libraries
(databricks-sql-connector, boto3, snowflake-connector-python) correctly
as far as syntax and call shape go, but treat a clean run of this script,
not a clean read of its source, as the actual pass/fail evidence - run it
for real against the POC sandbox before citing its output anywhere.

Usage:
    pip install databricks-sql-connector boto3 snowflake-connector-python
    export DATABRICKS_HOST=...  DATABRICKS_HTTP_PATH=...  DATABRICKS_TOKEN=...
    export SNOWFLAKE_ACCOUNT=...  SNOWFLAKE_USER=...  SNOWFLAKE_PRIVATE_KEY=...
    export KINESIS_STREAM_NAME=... AWS_REGION=us-east-1
    python run_poc_checks.py --objective all
    python run_poc_checks.py --objective streaming   # run one at a time while iterating
"""
from __future__ import annotations

import argparse
import os
import sys
import time
from dataclasses import dataclass


@dataclass
class CheckResult:
    objective: str
    passed: bool
    detail: str


def require_env(*names: str) -> dict:
    missing = [n for n in names if not os.environ.get(n)]
    if missing:
        raise SystemExit(f"Missing required environment variables: {', '.join(missing)}")
    return {n: os.environ[n] for n in names}


def check_streaming(gold_table: str, sent_count_hint: int | None) -> CheckResult:
    """Pass criterion: synthetic events observable in gold within the
    measured latency band, zero loss across a forced worker restart.
    This checks event count only - the "forced worker restart" half of
    the criterion is a manual step (restart the pipeline cluster mid-run,
    then re-run this check) this script cannot trigger on its own."""
    env = require_env("DATABRICKS_HOST", "DATABRICKS_HTTP_PATH", "DATABRICKS_TOKEN")
    from databricks import sql as dbsql

    with dbsql.connect(
        server_hostname=env["DATABRICKS_HOST"],
        http_path=env["DATABRICKS_HTTP_PATH"],
        access_token=env["DATABRICKS_TOKEN"],
    ) as conn:
        with conn.cursor() as cur:
            cur.execute(f"SELECT COUNT(*) FROM {gold_table} WHERE _synthetic = true")
            (count,) = cur.fetchone()

    if sent_count_hint is not None:
        loss = max(0, sent_count_hint - count)
        passed = loss == 0
        detail = f"{count:,} synthetic events in gold vs {sent_count_hint:,} sent (loss: {loss:,})"
    else:
        passed = count > 0
        detail = f"{count:,} synthetic events observed in gold (no sent-count hint supplied to check loss)"
    return CheckResult("streaming", passed, detail)


def check_identity_join(job_run_id: str) -> CheckResult:
    """Pass criterion: join completes without manual tuning; runtime
    measured and extrapolated to the full 3.2B-row table. This polls the
    Databricks Jobs API run status rather than querying a result table,
    since the pass criterion is about completion and runtime, not output
    correctness (there is no "correct" synthetic join result to check
    against)."""
    env = require_env("DATABRICKS_HOST", "DATABRICKS_TOKEN")
    import requests

    url = f"https://{env['DATABRICKS_HOST']}/api/2.1/jobs/runs/get"
    resp = requests.get(url, params={"run_id": job_run_id},
                         headers={"Authorization": f"Bearer {env['DATABRICKS_TOKEN']}"}, timeout=30)
    resp.raise_for_status()
    run = resp.json()
    state = run.get("state", {})
    life_cycle = state.get("life_cycle_state")
    result_state = state.get("result_state")
    passed = life_cycle == "TERMINATED" and result_state == "SUCCESS"

    runtime_ms = run.get("end_time", 0) - run.get("start_time", 0)
    runtime_s = runtime_ms / 1000 if runtime_ms > 0 else None
    extrapolation = ""
    if runtime_s and passed:
        # linear extrapolation only - a real identity join is unlikely to
        # scale perfectly linearly from 10-20M to 3.2B rows (shuffle and
        # skew effects grow non-linearly), so treat this as a rough floor
        # on the real runtime, not a prediction.
        scale_factor = 3_200_000_000 / 15_000_000  # adjust denominator to match --identifier-rows actually used
        extrapolation = f"; naive linear extrapolation to 3.2B rows: ~{runtime_s * scale_factor / 60:.0f} min (floor estimate, not a prediction)"

    detail = f"life_cycle={life_cycle}, result={result_state}, runtime={runtime_s}s{extrapolation}"
    return CheckResult("identity_join", passed, detail)


def check_clean_room(partner_account_connection: dict, offering_title: str, source_table: str) -> CheckResult:
    """Pass criterion: an aggregate query from the TEST partner account
    against the linked offering succeeds, AND a direct row-level query
    against the source table from the partner side is confirmed to
    fail."""
    import snowflake.connector

    aggregate_passed = False
    row_level_blocked = False
    details = []

    with snowflake.connector.connect(**partner_account_connection) as conn:
        cur = conn.cursor()
        try:
            cur.execute(f"SELECT COUNT(*) FROM {offering_title}")  # approved-template-style aggregate
            (count,) = cur.fetchone()
            aggregate_passed = True
            details.append(f"aggregate query succeeded, count={count}")
        except Exception as exc:  # noqa: BLE001 - we want to report any failure, not just a specific type
            details.append(f"aggregate query FAILED (should have succeeded): {exc}")

        try:
            cur.execute(f"SELECT * FROM {source_table} LIMIT 1")
            details.append("row-level query UNEXPECTEDLY SUCCEEDED - this is a policy failure, not a pass")
            row_level_blocked = False
        except Exception:  # noqa: BLE001 - failure here is the desired outcome
            row_level_blocked = True
            details.append("row-level query correctly blocked")

    passed = aggregate_passed and row_level_blocked
    return CheckResult("clean_room", passed, "; ".join(details))


def check_terraform_cicd(plan_exit_code: int) -> CheckResult:
    """Pass criterion: a full L0-L5 apply succeeds via the pipeline
    including the approval gate, and a subsequent plan shows no drift.
    This function just interprets the exit code `terraform plan
    -detailed-exitcode` already produces (0 = no changes, 2 = changes
    pending, 1 = error) - run that plan via terraform-apply.yml's
    drift-check job and pass its exit code here, rather than
    re-implementing plan logic in Python."""
    passed = plan_exit_code == 0
    detail = {0: "no drift", 1: "plan errored", 2: "drift detected"}.get(plan_exit_code, f"unexpected exit code {plan_exit_code}")
    return CheckResult("terraform_cicd", passed, detail)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--objective", choices=["streaming", "identity", "clean_room", "terraform", "all"], default="all")
    parser.add_argument("--gold-table", default="castiron_lakehouse_dev_gold.event_pipeline.gold_materialized_views")
    parser.add_argument("--sent-count", type=int, default=None, help="Events sent by generate_synthetic_events.py, for loss calculation")
    parser.add_argument("--identity-job-run-id", default=None)
    parser.add_argument("--offering-title", default=None)
    parser.add_argument("--source-table", default=None)
    parser.add_argument("--terraform-plan-exit-code", type=int, default=None)
    args = parser.parse_args()

    results: list[CheckResult] = []
    run_all = args.objective == "all"

    if run_all or args.objective == "streaming":
        results.append(check_streaming(args.gold_table, args.sent_count))

    if (run_all or args.objective == "identity") and args.identity_job_run_id:
        results.append(check_identity_join(args.identity_job_run_id))
    elif args.objective == "identity":
        print("Skipping identity check: --identity-job-run-id not supplied", file=sys.stderr)

    if (run_all or args.objective == "clean_room") and args.offering_title and args.source_table:
        conn = {
            "account": os.environ.get("SNOWFLAKE_PARTNER_ACCOUNT"),
            "user": os.environ.get("SNOWFLAKE_PARTNER_USER"),
            "private_key": os.environ.get("SNOWFLAKE_PARTNER_PRIVATE_KEY"),
        }
        results.append(check_clean_room(conn, args.offering_title, args.source_table))
    elif args.objective == "clean_room":
        print("Skipping clean room check: --offering-title/--source-table not supplied", file=sys.stderr)

    if (run_all or args.objective == "terraform") and args.terraform_plan_exit_code is not None:
        results.append(check_terraform_cicd(args.terraform_plan_exit_code))
    elif args.objective == "terraform":
        print("Skipping terraform check: --terraform-plan-exit-code not supplied", file=sys.stderr)

    print("\n=== POC objective results ===")
    all_passed = True
    for r in results:
        status = "PASS" if r.passed else "FAIL"
        all_passed = all_passed and r.passed
        print(f"[{status}] {r.objective}: {r.detail}")

    if not results:
        print("No checks ran - supply the required arguments for at least one objective.")
        sys.exit(2)

    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()
