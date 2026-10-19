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
  description = "Databricks account ID (UUID)"
  type        = string
}

variable "pricing_tier" {
  description = "Databricks workspace pricing tier"
  type        = string
  default     = "PREMIUM"
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "castiron-lakehouse"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
