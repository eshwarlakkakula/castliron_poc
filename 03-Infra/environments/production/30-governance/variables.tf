variable "project_name" {
  type    = string
  default = "castiron-lakehouse"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "databricks_account_id" {
  type = string
}

variable "catalog_names" {
  description = "Catalogs to create under the metastore"
  type        = list(string)
  default     = ["bronze", "silver", "gold"]
}

variable "clean_room_contribution_schema_name" {
  description = "Schema within the gold catalog that holds clean-room contribution tables"
  type        = string
  default     = "clean_room_contribution"
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "castiron-lakehouse"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
