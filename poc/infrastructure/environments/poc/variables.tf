variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "castiron-poc"
}

variable "kinesis_shard_count" {
  type    = number
  default = 1
}

variable "aurora_allowed_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "aurora_min_capacity" {
  type    = number
  default = 0.5
}

variable "aurora_max_capacity" {
  type    = number
  default = 1
}

variable "databricks_unity_catalog_principal_arn" {
  type    = string
  default = ""
}

variable "databricks_external_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "CastIron-Phase1-POC"
    Environment = "poc"
  }
}
