output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "vpc_endpoints_security_group_id" {
  value = module.network.vpc_endpoints_security_group_id
}

output "lakehouse_data_key_arn" {
  value = module.kms.lakehouse_data_key_arn
}

output "lakehouse_data_bucket_name" {
  value = module.storage.lakehouse_data_bucket_name
}

output "lakehouse_data_bucket_arn" {
  value = module.storage.lakehouse_data_bucket_arn
}

output "kinesis_stream_arn" {
  value = module.kinesis_consumer.stream_arn
}

output "kinesis_enhanced_fan_out_consumer_arn" {
  value = module.kinesis_consumer.enhanced_fan_out_consumer_arn
}

output "databricks_cross_account_role_arn" {
  value = module.iam_databricks.databricks_cross_account_role_arn
}

output "databricks_compute_instance_profile_arn" {
  value = module.iam_databricks.databricks_compute_instance_profile_arn
}
