variable "project_name" {
  type    = string
  default = "castiron-lakehouse"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "snowflake_account_region" {
  description = "Snowflake account region - must match the partner account's region"
  type        = string
  default     = "aws_us_east_1"
}

variable "dcr_application_warehouse_size" {
  type    = string
  default = "XSMALL"
}

variable "dcr_analysis_warehouse_size" {
  type    = string
  default = "XSMALL"
}

variable "monthly_credit_quota" {
  type    = number
  default = 25
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "castiron-lakehouse"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
