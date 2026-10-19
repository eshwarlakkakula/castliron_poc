terraform {
  required_version = ">= 1.7.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.50"
    }
  }
}

provider "databricks" {
  alias = "workspace"
  host  = "https://${data.terraform_remote_state.databricks_account.outputs.workspace_url}"
  token = data.terraform_remote_state.databricks_account.outputs.workspace_bootstrap_token
}
