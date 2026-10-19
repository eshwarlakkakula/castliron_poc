# Environment: dev | Layer: L3 Governance
# Unity Catalog metastore + catalogs, and the external-sharing service
# principal the Snowflake clean-room pattern (L5) depends on.

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "unity_catalog" {
  source = "../../../modules/databricks-unity-catalog"

  providers = {
    databricks.account   = databricks.account
    databricks.workspace = databricks.workspace
  }

  name_prefix                           = local.name_prefix
  databricks_account_id                 = var.databricks_account_id
  workspace_id                          = data.terraform_remote_state.databricks_account.outputs.workspace_id
  aws_region                            = var.aws_region
  metastore_storage_root_bucket         = data.terraform_remote_state.foundation.outputs.lakehouse_data_bucket_name
  metastore_storage_credential_role_arn = data.terraform_remote_state.foundation.outputs.databricks_cross_account_role_arn
  catalog_names                         = var.catalog_names
  tags                                  = var.tags
}

module "external_sharing" {
  source = "../../../modules/databricks-external-sharing"

  providers = {
    databricks.account   = databricks.account
    databricks.workspace = databricks.workspace
  }

  name_prefix                          = local.name_prefix
  clean_room_contribution_catalog_name = "${local.name_prefix}-gold"
  clean_room_contribution_schema_name  = var.clean_room_contribution_schema_name
  tags                                 = var.tags

  depends_on = [module.unity_catalog]
}
