output "kinesis_instance_profile_arn" {
  description = "Instance profile ARN for Databricks Settings > Instance profiles"
  value       = aws_iam_instance_profile.databricks_kinesis.arn
}

output "kinesis_instance_profile_role_arn" {
  description = "Underlying IAM role ARN for the Kinesis instance profile"
  value       = aws_iam_role.databricks_kinesis_instance_profile_role.arn
}

output "unity_catalog_storage_role_arn" {
  description = "IAM role ARN for the Unity Catalog storage credential"
  value       = aws_iam_role.unity_catalog_storage_role.arn
}

output "serverless_kinesis_reader_access_key_id" {
  description = "Access key ID for serverless compute Kinesis reads (instance profiles are not supported on serverless)"
  value       = aws_iam_access_key.serverless_kinesis_reader.id
}

output "serverless_kinesis_reader_secret_access_key" {
  description = "Secret access key for serverless compute Kinesis reads - store in a Databricks secret scope, never in plaintext config"
  value       = aws_iam_access_key.serverless_kinesis_reader.secret
  sensitive   = true
}
