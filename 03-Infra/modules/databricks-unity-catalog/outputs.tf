output "metastore_id" {
  description = "Unity Catalog metastore ID"
  value       = databricks_metastore.lakehouse_metastore.id
}

output "storage_credential_name" {
  description = "Storage credential name, referenced by the databricks-external-sharing module's Iceberg REST exposure"
  value       = databricks_storage_credential.lakehouse_storage_credential.name
}

output "catalog_ids" {
  description = "Map of catalog name to catalog ID"
  value       = { for name, cat in databricks_catalog.lakehouse_catalogs : name => cat.id }
}

output "catalog_names" {
  description = "Full (prefixed) catalog names created by this module"
  value       = [for name, cat in databricks_catalog.lakehouse_catalogs : cat.name]
}
