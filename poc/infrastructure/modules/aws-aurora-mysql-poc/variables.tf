variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "database_name" {
  description = "Initial database created on the cluster"
  type        = string
  default     = "castiron_poc"
}

variable "master_username" {
  description = "Master username for the cluster"
  type        = string
  default     = "castiron_admin"
}

variable "db_subnet_group_name" {
  description = "DB subnet group the cluster is placed in"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security group IDs attached to the cluster"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Assign a publicly reachable endpoint (required for Databricks Lakehouse Federation from outside this VPC, unless PrivateLink/VPC peering is set up instead)"
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Aurora Serverless v2 minimum ACUs"
  type        = number
  default     = 0.5
}

variable "max_capacity" {
  description = "Aurora Serverless v2 maximum ACUs"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "Aurora MySQL engine version"
  type        = string
  default     = "8.0.mysql_aurora.3.08.2"
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy (POC data only)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
