# Environment: dev | Layer: L5 Interoperability
# CastIron's own Snowflake provider account objects for the clean-room
# pattern. Deliberately the most isolated layer - its state cannot read or
# write anything in L1-L4's AWS/Databricks resources, only consumes their
# outputs as inputs. See scripts/register_clean_room_offering.sql for the
# post-apply registration step this layer does not attempt to automate.

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "snowflake_clean_room" {
  source = "../../../modules/snowflake-clean-room"

  name_prefix                          = local.name_prefix
  snowflake_account_region             = var.snowflake_account_region
  databricks_iceberg_rest_catalog_uri  = "https://${data.terraform_remote_state.databricks_account.outputs.workspace_url}/api/2.1/unity-catalog/iceberg-rest"
  databricks_oauth_client_id           = data.terraform_remote_state.governance.outputs.snowflake_catalog_integration_client_id
  databricks_oauth_client_secret       = data.terraform_remote_state.governance.outputs.snowflake_catalog_integration_client_secret
  clean_room_contribution_catalog_name = "${local.name_prefix}-gold"
  dcr_application_warehouse_size       = var.dcr_application_warehouse_size
  dcr_analysis_warehouse_size          = var.dcr_analysis_warehouse_size
  monthly_credit_quota                 = var.monthly_credit_quota
  tags                                 = var.tags
}
