terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.50"
    }
  }
}

# Account-level provider, authenticated with an account admin service
# principal. Credentials come from environment variables
# (DATABRICKS_CLIENT_ID / DATABRICKS_CLIENT_SECRET / DATABRICKS_ACCOUNT_ID
# / DATABRICKS_HOST=https://accounts.azuredatabricks.net or
# https://accounts.cloud.databricks.com) set by the GitHub Actions
# workflow from repository secrets - never hardcoded here.
provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}
