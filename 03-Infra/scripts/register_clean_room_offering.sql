-- Register the linked read-only Iceberg table and provider offering.
--
-- VERIFY BEFORE RUNNING: the CREATE ICEBERG TABLE syntax and the
-- SYSTEM$REGISTER_PROVIDER_OFFERING / SYSTEM$START_OFFERING_SECURITY_SCAN
-- calls below reflect the documented register -> scan -> promote workflow
-- for Snowflake Data Clean Rooms, but the Clean Rooms native app's exact
-- SQL surface changes between app versions. Confirm the current procedure
-- names and arguments against the installed Clean Rooms app version in
-- Snowsight (Data Products > Clean Rooms > the app's own SQL reference)
-- before wiring this into the pipeline for anything beyond a dry run.
--
-- Everything up to this point (database, schema, catalog integration,
-- warehouses) is created by the snowflake-clean-room Terraform module.
-- This script covers the steps that are not reliable Terraform resources
-- as of this writing: registering the Iceberg table itself, and
-- registering + scanning the provider offering for the Collaboration Data
-- Clean Room. Run this via the deploy-clean-room-offering.yml pipeline
-- (04-Pipelines), never by hand against production.
--
-- Required session variables (supplied by the pipeline, never hardcoded
-- here):
--   &{database_name}            - from module output clean_room_provider_database_name
--   &{schema_name}               - from module output clean_room_provider_schema_name (unqualified part)
--   &{catalog_integration_name}  - from module output databricks_iceberg_rest_catalog_integration_name
--   &{dcr_application_warehouse} - from module output dcr_application_warehouse_name
--   &{iceberg_table_name}        - the Unity Catalog table name to link, e.g. clean_room_contribution_events
--   &{offering_title}            - human-readable offering title shown to the partner
--   &{offering_description}      - offering description shown to the partner

USE WAREHOUSE &{dcr_application_warehouse};
USE DATABASE &{database_name};
USE SCHEMA &{schema_name};

-- Link the Unity Catalog table as a read-only Iceberg table. No data is
-- copied: Snowflake reads the Parquet/Iceberg metadata directly from S3
-- using short-lived credentials vended through the catalog integration.
CREATE OR REPLACE ICEBERG TABLE &{iceberg_table_name}
  CATALOG = '&{catalog_integration_name}'
  EXTERNAL_VOLUME = NULL
  CATALOG_TABLE_NAME = '&{iceberg_table_name}'
  AUTO_REFRESH = TRUE;

-- Confirm the link resolves and row counts look sane before registering
-- the offering - fail the pipeline here rather than publish a broken link.
SELECT COUNT(*) AS row_count FROM &{iceberg_table_name};

-- Register the provider offering. The partner's Collaboration Data Clean
-- Room links this offering under their own approved query templates and
-- join/column policies - this script does not grant the partner any
-- direct row-level access.
CALL SYSTEM$REGISTER_PROVIDER_OFFERING(
  offering_name => '&{offering_title}',
  description   => '&{offering_description}',
  content       => OBJECT_CONSTRUCT(
    'database', '&{database_name}',
    'schema',   '&{schema_name}',
    'table',    '&{iceberg_table_name}'
  )
);

-- Starts the security scan required before the offering can be promoted
-- for the partner to link. This script only STARTS it and returns - it
-- does not wait for a result. Polling the scan status and failing closed
-- if it does not reach PASSED within the timeout happens in the next
-- step of the calling workflow ("Poll security scan status and fail
-- closed" in 04-Pipelines/.github/workflows/deploy-clean-room-offering.yml),
-- not in this script. If you are running this file by hand (dry run
-- only, never against production per the note above), you must check the
-- scan status yourself before treating the offering as promotable.
CALL SYSTEM$START_OFFERING_SECURITY_SCAN('&{offering_title}');
