# Databricks notebook source
#
# SCAFFOLD - NOT VALIDATED. Writes the clean-room contribution table as
# Delta with UniForm enabled, so Unity Catalog can expose it through the
# Iceberg REST Catalog (03-Infra/modules/databricks-external-sharing) with
# no data copy. This is the CastIron-side half of the pattern validated in
# 03-Infra/scripts/register_clean_room_offering.sql.

# TODO(tokenization): the Technical Approach's clean-room cost tables
# describe contribution data as having "tokenized join keys" (Section
# 4.1) - the actual tokenization/hashing of device or household IDs
# before they reach this table is not implemented here and needs a
# decision on the tokenization scheme (confirm it is irreversible,
# confirm it is stable across days for frequency capping to work).

catalog = spark.conf.get("catalog_prefix", "REPLACE_WITH_CATALOG_PREFIX")

spark.sql(f"""
    CREATE TABLE IF NOT EXISTS {catalog}-gold.clean_room_contribution.events (
        -- TODO(schema): exact columns depend on the approved query
        -- templates and join/column policies the partner's Clean Rooms
        -- app will enforce (Technical Approach Section 6) - do not widen
        -- this schema beyond what's been approved for sharing.
        tokenized_household_id STRING,
        exposure_date DATE,
        equivalized_impressions DOUBLE
    )
    USING DELTA
    TBLPROPERTIES ('delta.universalFormat.enabledFormats' = 'iceberg')
""")

# TODO(write-logic): populate the table from gold's measurement output
# once compute_measurement.py has real logic - currently there is nothing
# upstream of this that isn't itself a placeholder.
