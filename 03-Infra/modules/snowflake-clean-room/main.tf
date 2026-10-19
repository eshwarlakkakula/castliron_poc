# L5 Interoperability - Snowflake clean-room provider side
# CastIron's own Snowflake provider account: the database/schema that will
# hold the linked read-only Iceberg table, the catalog integration pointing
# at Databricks' Unity Catalog Iceberg REST Catalog, and the two warehouses
# the clean-room pattern needs (DCR application, DCR analysis), each with a
# resource monitor so a runaway query cannot produce a surprise bill.
#
# Every resource type and attribute below was checked against the
# snowflakedb/snowflake provider's actual schema (terraform providers
# schema) before being written - see README.md for how to re-run that
# check. One exception: the CREATE CATALOG INTEGRATION ... ICEBERG REST
# statement inside snowflake_execute is raw SQL, which this module cannot
# schema-validate the way it can a native resource - confirm its syntax
# against the current Snowflake SQL reference before the first real apply.
#
# VERIFY BEFORE APPLY: registering the Iceberg table, installing the
# Collaboration Data Clean Room native app, and linking the provider
# offering into the partner's clean room are Snowflake operations this
# module intentionally does not attempt to automate as Terraform resources
# - the Data Clean Rooms native app's SQL surface is versioned separately
# from the Snowflake provider and changes between app versions. Those steps
# are scripted in scripts/register_clean_room_offering.sql (run by the
# deploy-clean-room-offering.yml pipeline, see 04-Pipelines) instead.

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 1.0"
    }
  }
}

locals {
  catalog_integration_name = upper(replace("${var.name_prefix}_databricks_iceberg_rest", "-", "_"))
}

resource "snowflake_database" "clean_room_provider_database" {
  name    = upper(replace("${var.name_prefix}_clean_room", "-", "_"))
  comment = "Holds the read-only Iceberg table linked from Unity Catalog for the Omnicom clean-room offering"
}

resource "snowflake_schema" "clean_room_provider_schema" {
  database = snowflake_database.clean_room_provider_database.name
  name     = "CONTRIBUTION"
  comment  = "Schema for the linked read-only Iceberg table"
}

# The ICEBERG_REST catalog integration itself is not yet a native resource
# in the Snowflake provider (checked against v1.x schema), so it is
# created via snowflake_execute, with a matching DROP on destroy. This
# keeps it in Terraform's lifecycle and state instead of pushing a
# structural, rarely-changing account object out to the SQL script.
resource "snowflake_execute" "databricks_iceberg_rest_catalog_integration" {
  execute = <<-SQL
    CREATE CATALOG INTEGRATION IF NOT EXISTS ${local.catalog_integration_name}
      CATALOG_SOURCE = ICEBERG_REST
      TABLE_FORMAT = ICEBERG
      CATALOG_NAMESPACE = '${var.clean_room_contribution_catalog_name}'
      REST_CONFIG = (
        CATALOG_URI  = '${var.databricks_iceberg_rest_catalog_uri}'
        WAREHOUSE    = '${var.clean_room_contribution_catalog_name}'
        CATALOG_NAME = '${var.clean_room_contribution_catalog_name}'
      )
      REST_AUTHENTICATION = (
        TYPE                 = OAUTH
        OAUTH_CLIENT_ID      = '${var.databricks_oauth_client_id}'
        OAUTH_CLIENT_SECRET  = '${var.databricks_oauth_client_secret}'
        OAUTH_TOKEN_URI      = '${var.databricks_iceberg_rest_catalog_uri}/v1/oauth/tokens'
      )
      ENABLED = TRUE;
  SQL

  revert = <<-SQL
    DROP CATALOG INTEGRATION IF EXISTS ${local.catalog_integration_name};
  SQL
}

# ---------------------------------------------------------------- warehouses
resource "snowflake_resource_monitor" "dcr_warehouse_resource_monitor" {
  name            = upper(replace("${var.name_prefix}_dcr_monitor", "-", "_"))
  credit_quota    = var.monthly_credit_quota
  frequency       = "MONTHLY"
  start_timestamp = "IMMEDIATELY"
  notify_triggers = [75, 90]
  suspend_trigger = 100
}

resource "snowflake_warehouse" "dcr_application_warehouse" {
  name                = upper(replace("${var.name_prefix}_dcr_app_wh", "-", "_"))
  comment             = "Collaboration Data Clean Room application warehouse - registers and serves the provider offering"
  warehouse_size      = var.dcr_application_warehouse_size
  auto_suspend        = var.dcr_warehouse_auto_suspend_seconds
  auto_resume         = true
  initially_suspended = true
  resource_monitor    = snowflake_resource_monitor.dcr_warehouse_resource_monitor.name
}

resource "snowflake_warehouse" "dcr_analysis_warehouse" {
  name                = upper(replace("${var.name_prefix}_dcr_analysis_wh", "-", "_"))
  comment             = "Ad hoc clean-room analysis warehouse - the analysis runner normally bears this compute per the clean-room agreement"
  warehouse_size      = var.dcr_analysis_warehouse_size
  auto_suspend        = var.dcr_warehouse_auto_suspend_seconds
  auto_resume         = true
  initially_suspended = true
  resource_monitor    = snowflake_resource_monitor.dcr_warehouse_resource_monitor.name
}

resource "snowflake_grant_privileges_to_account_role" "clean_room_schema_usage_grant" {
  account_role_name = "SYSADMIN"
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "${snowflake_database.clean_room_provider_database.name}.${snowflake_schema.clean_room_provider_schema.name}"
  }
}
