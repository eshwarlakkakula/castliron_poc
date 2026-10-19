output "databricks_cross_account_role_arn" {
  description = "Cross-account role ARN to register as the Databricks credential configuration"
  value       = aws_iam_role.databricks_cross_account_role.arn
}

output "databricks_compute_instance_profile_arn" {
  description = "Instance profile ARN to register with Databricks and attach to cluster policies"
  value       = aws_iam_instance_profile.databricks_compute_instance_profile.arn
}

output "databricks_compute_instance_role_arn" {
  description = "Role ARN backing the compute instance profile"
  value       = aws_iam_role.databricks_compute_instance_role.arn
}
