output "clean_room_provider_database_name" {
  value = module.snowflake_clean_room.clean_room_provider_database_name
}

output "clean_room_provider_schema_name" {
  value = module.snowflake_clean_room.clean_room_provider_schema_name
}

output "databricks_iceberg_rest_catalog_integration_name" {
  value = module.snowflake_clean_room.databricks_iceberg_rest_catalog_integration_name
}

output "dcr_application_warehouse_name" {
  value = module.snowflake_clean_room.dcr_application_warehouse_name
}

output "dcr_analysis_warehouse_name" {
  value = module.snowflake_clean_room.dcr_analysis_warehouse_name
}
