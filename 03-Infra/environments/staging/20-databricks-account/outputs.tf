output "workspace_id" {
  value = module.workspace.workspace_id
}

output "workspace_url" {
  value = module.workspace.workspace_url
}

output "workspace_bootstrap_token" {
  value     = module.workspace.workspace_bootstrap_token
  sensitive = true
}
