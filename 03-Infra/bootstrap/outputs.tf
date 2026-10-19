output "terraform_state_bucket_name" {
  description = "S3 bucket name to reference in every downstream layer's backend block"
  value       = aws_s3_bucket.terraform_state_bucket.bucket
}

output "terraform_state_lock_table_name" {
  description = "DynamoDB table name to reference in every downstream layer's backend block"
  value       = aws_dynamodb_table.terraform_state_lock_table.name
}

output "terraform_state_kms_key_arn" {
  description = "KMS key ARN used to encrypt Terraform state"
  value       = aws_kms_key.terraform_state_key.arn
}

output "terraform_ci_deployment_role_arn" {
  description = "IAM role ARN the GitHub Actions workflows assume via OIDC (role-to-assume input)"
  value       = aws_iam_role.terraform_ci_deployment_role.arn
}

output "github_actions_oidc_provider_arn" {
  description = "OIDC provider ARN, for reference by later layers that need to extend trust"
  value       = aws_iam_openid_connect_provider.github_actions_oidc_provider.arn
}
