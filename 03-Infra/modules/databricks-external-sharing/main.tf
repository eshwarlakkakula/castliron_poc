# L3 Governance - external sharing (Unity Catalog Iceberg REST)
# The OAuth service principal and grants that let an external engine (the
# CastIron Snowflake provider account, via its catalog integration) read
# the clean-room contribution tables through the Unity Catalog Iceberg REST
# Catalog API - read-only, short-lived vended credentials, no PAT.
#
# VERIFY BEFORE APPLY: account-level enablement of external data access /
# the Iceberg REST Catalog endpoint is a newer Unity Catalog capability and
# its exact Terraform resource (or whether it is still account-console/API
# only) should be confirmed against the current databricks/databricks
# provider docs before this layer is applied - do not assume the resource
# names below are the final word on that specific toggle.

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      version               = "~> 1.50"
      configuration_aliases = [databricks.account, databricks.workspace]
    }
  }
}

resource "databricks_service_principal" "snowflake_catalog_integration_principal" {
  provider     = databricks.account
  display_name = "${var.name_prefix}-snowflake-catalog-integration"
  active       = true
}

resource "databricks_service_principal_secret" "snowflake_catalog_integration_secret" {
  provider             = databricks.account
  service_principal_id = databricks_service_principal.snowflake_catalog_integration_principal.id
}

# No account-level role is granted to this principal - its only
# permissions are the workspace-level catalog/schema grants below, which is
# the full extent of what the Snowflake-side integration needs.

# Grants EXTERNAL USE SCHEMA on the clean-room contribution schema only -
# this principal cannot read any other schema or catalog in the metastore.
resource "databricks_grants" "clean_room_schema_external_use_grant" {
  provider = databricks.workspace
  schema   = "${var.clean_room_contribution_catalog_name}.${var.clean_room_contribution_schema_name}"

  grant {
    principal  = databricks_service_principal.snowflake_catalog_integration_principal.application_id
    privileges = ["EXTERNAL_USE_SCHEMA", "SELECT"]
  }
}

resource "databricks_grants" "clean_room_catalog_use_grant" {
  provider = databricks.workspace
  catalog  = var.clean_room_contribution_catalog_name

  grant {
    principal  = databricks_service_principal.snowflake_catalog_integration_principal.application_id
    privileges = ["USE_CATALOG"]
  }
}
