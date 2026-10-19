# Databricks notebook source
#
# SCAFFOLD - NOT VALIDATED. Hourly throttled JDBC upsert into Aurora
# MySQL (Technical Approach Section 4.1).
#
# TODO(aurora-contract) - required from CastIron before this can write to
# a real application database (see the engagement README "Inputs
# needed"):
#   - Real Aurora schema (table names, column types, keys) to upsert into
#   - Expected write volume and the acceptable performance impact/SLO on
#     the application database (Technical Approach's requirement is just
#     "No impact on application performance" - not yet a number)
#   - Idempotency rule: this job can retry on failure, so the write must
#     be safe to repeat - confirm the real natural key for the MERGE/
#     upsert ON clause, not assumed here

from pyspark.sql import functions as F

JDBC_URL_PLACEHOLDER = "REPLACE_WITH_AURORA_JDBC_URL"  # pulled from a secret scope, never hardcoded in a real run
TARGET_TABLE_PLACEHOLDER = "REPLACE_WITH_AURORA_TABLE"
STAGING_TABLE_PLACEHOLDER = "REPLACE_WITH_AURORA_TABLE_staging"

# TODO(natural-key): this is the one thing that cannot be a reasonable
# default - an idempotent MERGE is only as correct as its ON clause, and
# a wrong key silently corrupts the application database instead of
# failing loudly. Do not deploy this past the placeholder until CastIron
# confirms the real natural key.
NATURAL_KEY_COLUMNS_PLACEHOLDER = ["REPLACE_WITH_NATURAL_KEY_COLUMN"]

gold_df = spark.table("REPLACE_WITH_GOLD_SOURCE_TABLE")

# TODO(throttling): "throttled parallelism" (Technical Approach Section
# 4.1/4.3) - the actual connection/batch limits depend on the Aurora
# instance class and current application load, neither of which is known
# yet. Do not raise this above 1 without load-testing against a non-
# production Aurora instance first.
(
    gold_df.write.format("jdbc")
    .option("url", JDBC_URL_PLACEHOLDER)
    .option("dbtable", STAGING_TABLE_PLACEHOLDER)
    .option("numPartitions", 1)
    .option("truncate", "true")
    .mode("overwrite")
    .save()
)

# Idempotent MERGE from the staging table into the real target, run via a
# JDBC connection executing a single statement (Spark's JDBC writer has
# no native MERGE support, so this is a plain JDBC statement, not a
# DataFrame write) - safe to retry on failure, unlike the naive
# .mode("append") this replaces, which would have double-written rows on
# every job retry.
merge_sql = f"""
    INSERT INTO {TARGET_TABLE_PLACEHOLDER}
    SELECT * FROM {STAGING_TABLE_PLACEHOLDER}
    ON DUPLICATE KEY UPDATE
        {", ".join(f"{{col}} = VALUES({{col}})".format(col=c) for c in gold_df.columns if c not in NATURAL_KEY_COLUMNS_PLACEHOLDER)}
"""
# TODO(execute-merge): run merge_sql via a JDBC connection (e.g.
# java.sql.DriverManager through py4j, or a small JDBC helper) - not
# wired to an actual connection here since that needs the real
# JDBC_URL_PLACEHOLDER and credentials from a secret scope, neither of
# which exist in this scaffold. MySQL's "ON DUPLICATE KEY UPDATE" requires
# NATURAL_KEY_COLUMNS_PLACEHOLDER to be the target table's real primary
# key or a unique index - confirm that's true for the real schema before
# relying on this, not just that the SQL parses.
print(merge_sql)
