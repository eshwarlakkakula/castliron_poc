variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "kinesis_stream_arn" {
  description = "ARN of the Kinesis stream this instance profile may read from"
  type        = string
}

variable "unity_catalog_storage_bucket_arn" {
  description = "ARN of the S3 bucket backing the Unity Catalog external location (optional - leave empty to skip the storage-credential role entirely)"
  type        = string
  default     = ""
}

variable "databricks_unity_catalog_principal_arn" {
  description = "AWS principal ARN for the Unity Catalog storage-credential trust policy, generated per-account by Databricks (Catalog Explorer > External Data > Credentials). Required only if unity_catalog_storage_bucket_arn is set."
  type        = string
  default     = ""
}

variable "databricks_external_id" {
  description = "External ID paired with databricks_unity_catalog_principal_arn, generated per-account by Databricks. Required only if unity_catalog_storage_bucket_arn is set."
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
