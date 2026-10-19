# Databricks notebook source
#
# SCAFFOLD - NOT VALIDATED. This sets up the correct Lakeflow Declarative
# Pipeline shape (bronze -> silver -> gold, matching Technical Approach
# Section 4.1) with every TODO marking a decision that needs real input
# from CastIron before this can run against production traffic - see
# PHASE1-ENGAGEMENT-README.md "Inputs needed" list. Nothing here has been
# run against a cluster or checked against a real event schema.

import dlt
from pyspark.sql import functions as F

# TODO(schema-contract): replace with the real ad-server event schema.
# The current-state column contract is duplicated in five places
# including one that only exists as a COPY command pasted into the
# Firehose console (Technical Approach Section 2) - get the authoritative
# schema from the team that owns that COPY command before trusting this.
EVENT_SCHEMA_PLACEHOLDER = """
    request_id STRING,
    event_type STRING,
    event_timestamp TIMESTAMP,
    device_id STRING,
    ip_address STRING,
    user_agent STRING
"""


@dlt.table(
    name="bronze_events",
    comment="Immutable, replayable raw events from the Kinesis EFO consumer.",
)
def bronze_events():
    return (
        spark.readStream.format("kinesis")
        # TODO(kinesis-config): stream name / consumer ARN / shard count
        # are still open items (Technical Approach Section 9) - wire these
        # from the aws-kinesis-consumer module's outputs, not literals.
        .option("streamName", "REPLACE_WITH_KINESIS_STREAM_NAME")
        .option("consumerName", "lakeflow-ingest-consumer")
        .load()
        .withColumn("_ingested_at", F.current_timestamp())
    )


@dlt.table(
    name="silver_corrected_events",
    comment="Deduplicated, enriched events with a bounded-state request-to-event join.",
)
@dlt.expect_or_drop("valid_request_id", "request_id IS NOT NULL")
def silver_corrected_events():
    bronze = dlt.read_stream("bronze_events")
    # TODO(dedup-key): confirm this replaces the current-state
    # `dedup by max() per request_id` logic exactly, including its
    # tie-breaking rule, before treating this as equivalent.
    # TODO(enrichment): geo (MaxMind) and device/OS (ua-parser) enrichment
    # - confirm the licensed MaxMind database version and refresh cadence
    #   (Technical Approach, reference-data volume) before wiring this in.
    # TODO(watermark): pick a watermark short enough to keep streaming
    # state bounded (see the review note on 48h join state), with late
    # corrections handled by the separate AUTO CDC correction feed below,
    # not by widening this watermark.
    return bronze.withWatermark("_ingested_at", "10 minutes").dropDuplicates(["request_id"])


# TODO(auto-cdc): the 48-hour correction feed (Technical Approach Section
# 4.1) applies ordered partner restatements into silver via AUTO CDC INTO -
# not yet implemented here. Needs the certified reconciliation tolerance
# and parity acceptance threshold from CastIron before this is more than a
# structural placeholder.


@dlt.table(
    name="gold_materialized_views",
    comment="Reach, frequency, and reconciliation marts for the SPA and the clean room.",
)
def gold_materialized_views():
    silver = dlt.read("silver_corrected_events")
    # TODO(measurement-logic): this is a placeholder aggregate, not the
    # certified reach/frequency/equivalization calculation - see
    # src/measurement/README.md for exactly what's missing and why it is
    # not implemented here.
    return silver.groupBy(F.window("event_timestamp", "1 day")).agg(
        F.countDistinct("device_id").alias("daily_reach_placeholder")
    )
