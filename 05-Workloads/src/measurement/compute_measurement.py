# Databricks notebook source
#
# SCAFFOLD - NOT VALIDATED. This is deliberately the thinnest stub in the
# bundle, because it is the one with the least defensible placeholder
# logic to write: reach, frequency, and equivalization are contractual
# numbers an agency partner will audit, and this repo has no certified
# definition for any of them.
#
# TODO(measurement-definitions) - required from CastIron before this file
# can contain real logic, not a placeholder count (see the engagement
# README "Inputs needed" list and Technical Approach Section 4.1):
#   - Equivalization methodology (how impressions across device types/
#     durations convert to a common unit)
#   - Household reach and frequency calculation on the 30-day rolling
#     window - exact de-duplication and windowing rules
#   - Partner delivery reconciliation tolerance (Technical Approach says
#     "48h restatement" but not the acceptance threshold for what counts
#     as reconciled vs. a discrepancy to investigate)
#   - Parity acceptance threshold for the Redshift shadow-run comparison
#     (Technical Approach Section 7.1 references this but it is not a
#     number yet)
#
# Writing a plausible-looking reach/frequency formula without those inputs
# would produce a number that LOOKS correct and cannot be trusted - that
# is worse than an explicit placeholder. See bronze_silver_gold_pipeline.py
# for the (also placeholder) daily_reach_placeholder this would replace.

raise NotImplementedError(
    "Measurement logic intentionally not implemented - certified "
    "definitions required from CastIron first. See this file's header."
)
