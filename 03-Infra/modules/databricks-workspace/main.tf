# L2 Databricks account - workspace
# Registers the cross-account credential, the customer-managed VPC as a
# Databricks network configuration, and creates the workspace itself.
# Requires the account-level Databricks provider (authenticated with an
# account admin service principal, not a workspace token - see
# environments/*/providers.tf).
#
# Prerequisite: Databricks must already be subscribed through AWS
# Marketplace with this AWS account linked as the payment method (Technical
# Approach Section 7) before this layer is applied.

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      version               = "~> 1.50"
      configuration_aliases = [databricks.account]
    }
  }
}

resource "databricks_mws_credentials" "lakehouse_cross_account_credentials" {
  provider         = databricks.account
  account_id       = var.databricks_account_id
  credentials_name = "${var.name_prefix}-cross-account-credentials"
  role_arn         = var.databricks_cross_account_role_arn
}

resource "databricks_mws_storage_configurations" "lakehouse_root_storage" {
  provider                   = databricks.account
  account_id                 = var.databricks_account_id
  storage_configuration_name = "${var.name_prefix}-root-storage"
  bucket_name                = var.lakehouse_data_bucket_name
}

resource "databricks_mws_networks" "lakehouse_network_configuration" {
  provider           = databricks.account
  account_id         = var.databricks_account_id
  network_name       = "${var.name_prefix}-network-config"
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.security_group_id]
}

resource "databricks_mws_workspaces" "lakehouse_workspace" {
  provider       = databricks.account
  account_id     = var.databricks_account_id
  workspace_name = "${var.name_prefix}-workspace"
  aws_region     = var.aws_region
  pricing_tier   = var.pricing_tier

  credentials_id           = databricks_mws_credentials.lakehouse_cross_account_credentials.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.lakehouse_root_storage.storage_configuration_id
  network_id               = databricks_mws_networks.lakehouse_network_configuration.network_id

  token {
    comment = "${var.name_prefix} Terraform-managed workspace PAT for bootstrap only; day-2 automation uses OAuth service principals (L4)."
  }
}
