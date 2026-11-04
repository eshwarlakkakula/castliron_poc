# Databricks notebook source
from pyspark.sql import functions as F

dbutils.widgets.text("catalog", "castiron_poc")
dbutils.widgets.text("schema", "event_pipeline")
dbutils.widgets.text("identifiers_volume_path", "/Volumes/castiron_poc/event_pipeline/identity_inputs")

catalog = dbutils.widgets.get("catalog")
schema = dbutils.widgets.get("schema")
volume_path = dbutils.widgets.get("identifiers_volume_path")

identifiers = spark.read.parquet(f"{volume_path}/identifiers.parquet")
probes = spark.read.parquet(f"{volume_path}/probes.parquet")

resolved = probes.join(identifiers, on="device_id", how="left")

resolved.write.mode("overwrite").saveAsTable(f"{catalog}.{schema}.identity_resolution_results")

match_count = resolved.filter(F.col("household_id").isNotNull()).count()
total_count = resolved.count()
print(f"Resolved {match_count:,} / {total_count:,} probes ({match_count / total_count:.1%} match rate)")
