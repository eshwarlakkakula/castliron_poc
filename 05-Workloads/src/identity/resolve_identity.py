# Databricks notebook source
#
# SCAFFOLD - NOT VALIDATED. Structural placeholder for the daily join of
# ~8M device probes against the licensed identifier table (Technical
# Approach Section 4.1). Cannot be completed without CastIron's input -
# see the TODOs below and the engagement README's "Inputs needed" list.

from pyspark.sql import functions as F

# TODO(licensor-selection): the identity licensor is still unselected
# (Technical Approach Section 9 open item) - the identifier table's
# schema, join key, and refresh cadence all depend on which licensor is
# chosen and whether the graph is hosted or delivered resident.
IDENTIFIER_TABLE_PLACEHOLDER = "REPLACE_WITH_LICENSED_IDENTIFIER_TABLE"

# TODO(profile-agents): if CustomerLake Profile Agents is confirmed capable
# of device-ID/household resolution (open question, Technical Approach
# Section 10.1), this job's approach may change substantially - don't
# build out the licensed-graph join path further until that's answered.


def resolve_daily_probes(probes_df, identifiers_df):
    """Join today's device probes against the identifier table.

    TODO(join-strategy): confirm the real join key and expected match
    rate with the identity team before trusting broadcast-join sizing
    assumptions here - 8M probes against a 3.2B-row table is join-bound,
    not ingest-bound (Technical Approach Section 3), so the physical plan
    matters more than it would for a simple lookup.
    """
    return probes_df.join(identifiers_df, on="device_id", how="left")


# TODO(output-contract): the result is exposed through a stable view "so
# the licensor can change without rework" (Technical Approach Section
# 4.1) - that view is not defined here yet because its schema depends on
# the still-open hosted-vs-resident decision.
