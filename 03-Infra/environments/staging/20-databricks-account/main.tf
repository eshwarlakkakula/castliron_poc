# Environment: dev | Layer: L2 Databricks account/workspace
# Prerequisite: Databricks must already be subscribed through AWS
# Marketplace with this AWS account linked as the payment method before
# this layer is applied (Technical Approach, Section 7).

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "workspace" {
  source = "../../../modules/databricks-workspace"

  providers = {
    databricks.account = databricks.account
  }

  name_prefix                       = local.name_prefix
  databricks_account_id             = var.databricks_account_id
  aws_region                        = var.aws_region
  pricing_tier                      = var.pricing_tier
  databricks_cross_account_role_arn = data.terraform_remote_state.foundation.outputs.databricks_cross_account_role_arn
  lakehouse_data_bucket_name        = data.terraform_remote_state.foundation.outputs.lakehouse_data_bucket_name
  vpc_id                            = data.terraform_remote_state.foundation.outputs.vpc_id
  private_subnet_ids                = data.terraform_remote_state.foundation.outputs.private_subnet_ids
  security_group_id                 = data.terraform_remote_state.foundation.outputs.vpc_endpoints_security_group_id
  tags                              = var.tags
}
