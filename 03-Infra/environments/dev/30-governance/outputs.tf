output "metastore_id" {
  value = module.unity_catalog.metastore_id
}

output "catalog_names" {
  value = module.unity_catalog.catalog_names
}

output "snowflake_catalog_integration_client_id" {
  value = module.external_sharing.snowflake_catalog_integration_client_id
}

output "snowflake_catalog_integration_client_secret" {
  value     = module.external_sharing.snowflake_catalog_integration_client_secret
  sensitive = true
}
