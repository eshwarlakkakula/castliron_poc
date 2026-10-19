variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "databricks_account_id" {
  description = "Databricks account ID (UUID)"
  type        = string
}

variable "aws_region" {
  description = "AWS region the workspace deploys into"
  type        = string
}

variable "databricks_cross_account_role_arn" {
  description = "Cross-account IAM role ARN (from the aws-iam-databricks module)"
  type        = string
}

variable "lakehouse_data_bucket_name" {
  description = "Root S3 bucket name for the workspace's managed storage (from the aws-storage module)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the workspace's customer-managed network (from the aws-network module)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for workspace compute (from the aws-network module)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID attached to the workspace's compute resources"
  type        = string
}

variable "pricing_tier" {
  description = "Databricks pricing tier for this workspace"
  type        = string
  default     = "PREMIUM"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
