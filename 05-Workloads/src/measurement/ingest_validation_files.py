# Databricks notebook source
#
# SCAFFOLD - NOT VALIDATED. Auto Loader ingest for third-party validation
# files (Technical Approach Section 4.1).

# TODO(source-location): confirm the real S3/SFTP drop location and file
# format for third-party validation files - not specified in the brief or
# the Technical Approach beyond "third-party validation ingest".

validation_files_df = (
    spark.readStream.format("cloudFiles")
    .option("cloudFiles.format", "csv")  # TODO: confirm actual format
    .option("cloudFiles.schemaLocation", "REPLACE_WITH_SCHEMA_LOCATION")
    .load("REPLACE_WITH_VALIDATION_FILES_PATH")
)

# TODO(validation-logic): what does "validation" mean here - compare
# against gold's exposure counts? Flag discrepancies above the (not yet
# defined) reconciliation tolerance? Needs the same certified-definitions
# input as compute_measurement.py before this is more than an ingest stub.
