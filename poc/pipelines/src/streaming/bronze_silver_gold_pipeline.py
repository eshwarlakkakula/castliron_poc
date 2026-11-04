# Databricks notebook source
import dlt
from pyspark.sql import functions as F
from pyspark.sql.types import StringType, StructField, StructType, TimestampType, BooleanType

EVENT_SCHEMA = StructType([
    StructField("request_id", StringType()),
    StructField("event_type", StringType()),
    StructField("event_timestamp", TimestampType()),
    StructField("device_id", StringType()),
    StructField("ip_address", StringType()),
    StructField("user_agent", StringType()),
    StructField("_synthetic", BooleanType()),
])


@dlt.table(
    name="bronze_events",
    comment="Raw events consumed directly from the Kinesis stream via a Unity Catalog service credential.",
)
def bronze_events():
    stream_name = spark.conf.get("ingest.kinesis_stream_name")
    region = spark.conf.get("ingest.kinesis_region")
    service_credential = spark.conf.get("ingest.kinesis_service_credential")

    raw = (
        spark.readStream.format("kinesis")
        .option("streamName", stream_name)
        .option("region", region)
        .option("serviceCredential", service_credential)
        .load()
    )

    parsed = raw.select(
        F.from_json(F.col("data").cast("string"), EVENT_SCHEMA).alias("event")
    ).select("event.*")

    return parsed.withColumn("_ingested_at", F.current_timestamp())


@dlt.table(
    name="silver_corrected_events",
    comment="Deduplicated events, keyed on request_id.",
)
@dlt.expect_or_drop("valid_request_id", "request_id IS NOT NULL")
def silver_corrected_events():
    bronze = dlt.read_stream("bronze_events")
    return bronze.withWatermark("_ingested_at", "10 minutes").dropDuplicates(["request_id"])


@dlt.table(
    name="gold_events",
    comment="Row-level deduplicated events, exposed for POC loss/latency checks.",
)
def gold_events():
    return dlt.read_stream("silver_corrected_events")
