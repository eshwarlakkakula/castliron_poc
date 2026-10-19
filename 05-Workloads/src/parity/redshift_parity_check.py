# Databricks notebook source
#
# SCAFFOLD - the comparison engine below (compare_metric, reconcile_report)
# is real, generic logic and has been unit-tested outside this notebook
# (see 05-Workloads/src/parity/test_redshift_parity_check.py) against
# synthetic data. What's NOT implemented is the list of the real 15
# packaged reports and their actual Redshift/gold queries - REPORT_SPECS
# below is a 2-entry illustrative placeholder, not the real list.
#
# TODO(report-inventory): get the real list of ~15 packaged reports and,
# for each, the Redshift view/query that currently serves it and the
# Databricks gold query meant to replace it (Technical Approach Section
# 2: "SPA via JDBC: ~15 packaged reports"). Nothing about WHICH reports
# these are is specified anywhere in the supplied brief or Technical
# Approach beyond the count.
# TODO(tolerance): reconciliation_tolerance_pct is a job parameter
# defaulting to 0 (Technical Approach Section 9 open item - no certified
# tolerance exists yet). Raise it only once CastIron supplies a real
# number, not based on what makes a report happen to pass.

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class ReportSpec:
    name: str
    redshift_query: str  # read via Lakehouse Federation - a read-only path, confirmed correct per Technical Approach Section 10.3
    gold_query: str
    metric_columns: list[str]  # numeric columns to compare (row count is always compared too)


# TODO(report-inventory): replace with the real ~15 reports.
REPORT_SPECS = [
    ReportSpec(
        name="daily_impressions_by_campaign",
        redshift_query="SELECT campaign_id, SUM(impressions) AS impressions FROM redshift_federation.reporting.daily_impressions GROUP BY campaign_id",
        gold_query="SELECT campaign_id, SUM(impressions) AS impressions FROM REPLACE_WITH_GOLD_CATALOG.gold.daily_impressions GROUP BY campaign_id",
        metric_columns=["impressions"],
    ),
    ReportSpec(
        name="household_reach_frequency",
        redshift_query="SELECT report_date, reach, frequency FROM redshift_federation.reporting.household_reach_frequency",
        gold_query="SELECT report_date, reach, frequency FROM REPLACE_WITH_GOLD_CATALOG.gold.household_reach_frequency",
        metric_columns=["reach", "frequency"],
    ),
]


def compare_metric(redshift_value: float, gold_value: float, tolerance_pct: float) -> tuple[bool, float]:
    """Returns (within_tolerance, pct_difference). Handles the zero-baseline
    case explicitly rather than dividing by zero."""
    if redshift_value == 0:
        pct_difference = 0.0 if gold_value == 0 else float("inf")
    else:
        pct_difference = abs(gold_value - redshift_value) / abs(redshift_value) * 100
    return pct_difference <= tolerance_pct, pct_difference


def reconcile_report(spec: ReportSpec, redshift_df, gold_df, tolerance_pct: float) -> dict:
    """redshift_df / gold_df: pandas-like DataFrames already keyed/sorted
    the same way (grain alignment is the caller's job, via the queries in
    ReportSpec - this function only compares, it does not join or align)."""
    result = {
        "report": spec.name,
        "row_count_redshift": len(redshift_df),
        "row_count_gold": len(gold_df),
        "row_count_match": len(redshift_df) == len(gold_df),
        "metrics": {},
        "passed": True,
    }
    if not result["row_count_match"]:
        result["passed"] = False

    for col in spec.metric_columns:
        redshift_total = float(redshift_df[col].sum())
        gold_total = float(gold_df[col].sum())
        within_tolerance, pct_diff = compare_metric(redshift_total, gold_total, tolerance_pct)
        result["metrics"][col] = {
            "redshift_total": redshift_total,
            "gold_total": gold_total,
            "pct_difference": pct_diff,
            "within_tolerance": within_tolerance,
        }
        if not within_tolerance:
            result["passed"] = False

    return result


def run(tolerance_pct: float) -> list[dict]:  # pragma: no cover - needs a real Spark session + Federation connection
    # TODO: replace with real spark.sql(...).toPandas() calls once
    # Lakehouse Federation is configured against the real Redshift
    # instance and REPORT_SPECS holds the real report list.
    results = []
    for spec in REPORT_SPECS:
        redshift_df = spark.sql(spec.redshift_query).toPandas()  # noqa: F821 - `spark` is injected by the notebook runtime
        gold_df = spark.sql(spec.gold_query).toPandas()  # noqa: F821
        results.append(reconcile_report(spec, redshift_df, gold_df, tolerance_pct))
    return results


if __name__ == "__main__":  # pragma: no cover
    tolerance = float(dbutils.widgets.get("reconciliation_tolerance_pct"))  # noqa: F821 - injected by the job runtime
    all_results = run(tolerance)
    failed = [r for r in all_results if not r["passed"]]
    for r in all_results:
        print(r)
    if failed:
        raise SystemExit(f"{len(failed)} of {len(all_results)} reports failed parity: {[r['report'] for r in failed]}")
