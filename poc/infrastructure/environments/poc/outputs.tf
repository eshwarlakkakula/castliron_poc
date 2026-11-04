output "stream_name" {
  value = module.kinesis_consumer.stream_name
}

output "stream_arn" {
  value = module.kinesis_consumer.stream_arn
}

output "enhanced_fan_out_consumer_arn" {
  value = module.kinesis_consumer.enhanced_fan_out_consumer_arn
}

output "kinesis_instance_profile_arn" {
  value = module.databricks_access.kinesis_instance_profile_arn
}

output "kinesis_instance_profile_role_arn" {
  value = module.databricks_access.kinesis_instance_profile_role_arn
}

output "unity_catalog_storage_role_arn" {
  value = module.databricks_access.unity_catalog_storage_role_arn
}

output "serverless_kinesis_reader_access_key_id" {
  value = module.databricks_access.serverless_kinesis_reader_access_key_id
}

output "serverless_kinesis_reader_secret_access_key" {
  value     = module.databricks_access.serverless_kinesis_reader_secret_access_key
  sensitive = true
}

output "unity_catalog_storage_bucket_name" {
  value = module.s3_storage.bucket_name
}

output "aurora_cluster_endpoint" {
  value = module.aurora_mysql.cluster_endpoint
}

output "aurora_port" {
  value = module.aurora_mysql.port
}

output "aurora_database_name" {
  value = module.aurora_mysql.database_name
}

output "aurora_master_user_secret_arn" {
  value = module.aurora_mysql.master_user_secret_arn
}

output "aurora_security_group_id" {
  value = module.networking.security_group_id
}
