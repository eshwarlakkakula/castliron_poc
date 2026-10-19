variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "databricks_account_id" {
  description = "Databricks account ID (UUID)"
  type        = string
}

variable "workspace_id" {
  description = "Workspace ID to assign the metastore to (from the databricks-workspace module)"
  type        = string
}

variable "aws_region" {
  description = "AWS region, used to select/verify the regional metastore"
  type        = string
}

variable "metastore_storage_root_bucket" {
  description = "S3 bucket used as the Unity Catalog metastore's default storage root"
  type        = string
}

variable "metastore_storage_credential_role_arn" {
  description = "IAM role ARN Unity Catalog assumes to access the metastore storage root"
  type        = string
}

variable "catalog_names" {
  description = "Catalogs to create under this metastore, e.g. [\"bronze\", \"silver\", \"gold\"]"
  type        = list(string)
  default     = ["bronze", "silver", "gold"]
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
