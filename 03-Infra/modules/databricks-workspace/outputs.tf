output "workspace_id" {
  description = "Databricks workspace ID, used by downstream layers' workspace-level provider configuration"
  value       = databricks_mws_workspaces.lakehouse_workspace.workspace_id
}

output "workspace_url" {
  description = "Workspace URL"
  value       = databricks_mws_workspaces.lakehouse_workspace.workspace_url
}

output "workspace_bootstrap_token" {
  description = "Bootstrap personal access token - used only to seed the workspace-level provider before OAuth service principals (L4) take over"
  value       = databricks_mws_workspaces.lakehouse_workspace.token[0].token_value
  sensitive   = true
}
