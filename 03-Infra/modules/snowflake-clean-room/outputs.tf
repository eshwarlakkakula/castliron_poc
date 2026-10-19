output "clean_room_provider_database_name" {
  description = "Database name holding the linked read-only Iceberg table"
  value       = snowflake_database.clean_room_provider_database.name
}

output "clean_room_provider_schema_name" {
  description = "Fully qualified schema name for the register-offering script"
  value       = "${snowflake_database.clean_room_provider_database.name}.${snowflake_schema.clean_room_provider_schema.name}"
}

output "databricks_iceberg_rest_catalog_integration_name" {
  description = "Catalog integration name, referenced by the CREATE ICEBERG TABLE statement in the register-offering script"
  value       = local.catalog_integration_name
}

output "dcr_application_warehouse_name" {
  description = "DCR application warehouse name"
  value       = snowflake_warehouse.dcr_application_warehouse.name
}

output "dcr_analysis_warehouse_name" {
  description = "DCR analysis warehouse name"
  value       = snowflake_warehouse.dcr_analysis_warehouse.name
}
