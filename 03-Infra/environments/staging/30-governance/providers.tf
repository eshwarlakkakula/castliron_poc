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
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

# Workspace-level provider, scoped to the workspace L2 created. Uses the
# bootstrap token only to seed this layer; once the first workspace-level
# OAuth service principal exists (created in L4), switch this provider
# block to client_id/client_secret auth and retire the bootstrap token.
provider "databricks" {
  alias = "workspace"
  host  = "https://${data.terraform_remote_state.databricks_account.outputs.workspace_url}"
  token = data.terraform_remote_state.databricks_account.outputs.workspace_bootstrap_token
}
