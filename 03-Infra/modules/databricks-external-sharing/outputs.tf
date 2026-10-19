output "snowflake_catalog_integration_client_id" {
  description = "OAuth client ID (application ID) to configure in Snowflake's catalog integration"
  value       = databricks_service_principal.snowflake_catalog_integration_principal.application_id
}

output "snowflake_catalog_integration_client_secret" {
  description = "OAuth client secret to configure in Snowflake's catalog integration - store in the CI secret manager, never in state output consumers' logs"
  value       = databricks_service_principal_secret.snowflake_catalog_integration_secret.secret
  sensitive   = true
}
