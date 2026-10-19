"""Unit tests for the parity comparison engine - the one part of
redshift_parity_check.py that doesn't need a real Spark/Redshift
connection to verify. Run with: python test_redshift_parity_check.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import pandas as pd  # noqa: E402
from redshift_parity_check import ReportSpec, compare_metric, reconcile_report  # noqa: E402


def check(label: str, condition: bool) -> None:
    status = "PASS" if condition else "FAIL"
    print(f"[{status}] {label}")
    if not condition:
        global _any_failed
        _any_failed = True


_any_failed = False


def test_compare_metric_exact_match():
    within, pct = compare_metric(1000.0, 1000.0, tolerance_pct=0)
    check("exact match within 0% tolerance", within and pct == 0.0)


def test_compare_metric_within_tolerance():
    within, pct = compare_metric(1000.0, 1005.0, tolerance_pct=1.0)
    check("0.5% diff within 1% tolerance", within)
    check("pct_difference computed correctly (~0.5%)", abs(pct - 0.5) < 0.01)


def test_compare_metric_exceeds_tolerance():
    within, pct = compare_metric(1000.0, 1050.0, tolerance_pct=1.0)
    check("5% diff exceeds 1% tolerance", not within)


def test_compare_metric_zero_baseline_both_zero():
    within, pct = compare_metric(0.0, 0.0, tolerance_pct=0)
    check("zero vs zero does not divide by zero and passes", within and pct == 0.0)


def test_compare_metric_zero_baseline_nonzero_actual():
    within, pct = compare_metric(0.0, 5.0, tolerance_pct=0)
    check("zero vs nonzero fails (infinite pct diff), does not crash", not within and pct == float("inf"))


def test_reconcile_report_row_count_mismatch_fails():
    spec = ReportSpec("test_report", "irrelevant", "irrelevant", metric_columns=["impressions"])
    redshift_df = pd.DataFrame({"impressions": [100, 200, 300]})
    gold_df = pd.DataFrame({"impressions": [100, 200]})
    result = reconcile_report(spec, redshift_df, gold_df, tolerance_pct=0)
    check("row count mismatch (3 vs 2) fails the report", not result["passed"])
    check("row_count_match reported correctly", result["row_count_match"] is False)


def test_reconcile_report_all_pass():
    spec = ReportSpec("test_report", "irrelevant", "irrelevant", metric_columns=["impressions", "clicks"])
    redshift_df = pd.DataFrame({"impressions": [100, 200], "clicks": [5, 10]})
    gold_df = pd.DataFrame({"impressions": [100, 200], "clicks": [5, 10]})
    result = reconcile_report(spec, redshift_df, gold_df, tolerance_pct=0)
    check("identical data passes with 0% tolerance", result["passed"])
    check("both metric columns compared", set(result["metrics"].keys()) == {"impressions", "clicks"})


def test_reconcile_report_metric_discrepancy_fails():
    spec = ReportSpec("test_report", "irrelevant", "irrelevant", metric_columns=["impressions"])
    redshift_df = pd.DataFrame({"impressions": [100, 200]})  # sum = 300
    gold_df = pd.DataFrame({"impressions": [100, 250]})      # sum = 350, 16.7% over
    result = reconcile_report(spec, redshift_df, gold_df, tolerance_pct=5)
    check("16.7% metric discrepancy exceeds 5% tolerance and fails", not result["passed"])
    check("row counts still match independently", result["row_count_match"])


if __name__ == "__main__":
    for name, fn in list(globals().items()):
        if name.startswith("test_"):
            fn()
    sys.exit(1 if _any_failed else 0)
