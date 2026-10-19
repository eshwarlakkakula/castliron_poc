variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "databricks_account_id" {
  description = "Databricks account ID (UUID), used in the cross-account trust policy condition"
  type        = string
}

variable "lakehouse_data_bucket_arn" {
  description = "ARN of the lakehouse S3 bucket this role may access (from the aws-storage module)"
  type        = string
}

variable "lakehouse_kms_key_arn" {
  description = "ARN of the lakehouse KMS key this role may use (from the aws-kms module)"
  type        = string
}

variable "kinesis_stream_arn" {
  description = "ARN of the Kinesis data stream the Databricks workspace reads from"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
