# L3 Governance - Unity Catalog
# Metastore, storage credential, external location, metastore assignment,
# and the bronze/silver/gold catalogs. This is the governance layer every
# later layer (compute policies, clean-room interoperability) depends on,
# and it must never be able to affect L2's workspace or L1's network.

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

resource "databricks_metastore" "lakehouse_metastore" {
  provider      = databricks.account
  name          = "${var.name_prefix}-metastore"
  storage_root  = "s3://${var.metastore_storage_root_bucket}/metastore"
  region        = var.aws_region
  owner         = "account admins"
  force_destroy = false
}

resource "databricks_metastore_data_access" "lakehouse_metastore_storage_credential" {
  provider     = databricks.account
  metastore_id = databricks_metastore.lakehouse_metastore.id
  name         = "${var.name_prefix}-metastore-storage-credential"

  aws_iam_role {
    role_arn = var.metastore_storage_credential_role_arn
  }

  is_default = true
}

resource "databricks_metastore_assignment" "lakehouse_metastore_assignment" {
  provider     = databricks.account
  workspace_id = var.workspace_id
  metastore_id = databricks_metastore.lakehouse_metastore.id
}

resource "databricks_storage_credential" "lakehouse_storage_credential" {
  provider = databricks.workspace
  name     = "${var.name_prefix}-storage-credential"

  aws_iam_role {
    role_arn = var.metastore_storage_credential_role_arn
  }

  depends_on = [databricks_metastore_assignment.lakehouse_metastore_assignment]
}

resource "databricks_external_location" "lakehouse_external_location" {
  provider        = databricks.workspace
  name            = "${var.name_prefix}-lakehouse-external-location"
  url             = "s3://${var.metastore_storage_root_bucket}/lakehouse"
  credential_name = databricks_storage_credential.lakehouse_storage_credential.name
}

resource "databricks_catalog" "lakehouse_catalogs" {
  for_each     = toset(var.catalog_names)
  provider     = databricks.workspace
  name         = "${var.name_prefix}-${each.value}"
  metastore_id = databricks_metastore.lakehouse_metastore.id
  storage_root = "s3://${var.metastore_storage_root_bucket}/lakehouse/${each.value}"
  comment      = "${each.value} tier of the Phase 1 lakehouse"

  depends_on = [databricks_external_location.lakehouse_external_location]
}

resource "databricks_default_namespace_setting" "lakehouse_default_catalog" {
  provider = databricks.workspace
  namespace {
    value = databricks_catalog.lakehouse_catalogs["bronze"].name
  }
}
