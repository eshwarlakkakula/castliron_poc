variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "instance_profile_arn" {
  description = "Instance profile ARN clusters launch with (from the aws-iam-databricks module)"
  type        = string
}

variable "streaming_driver_node_type" {
  description = "Node type for the always-on streaming pipeline's driver"
  type        = string
  default     = "r6gd.2xlarge"
}

variable "streaming_worker_node_type" {
  description = "Node type for the always-on streaming pipeline's workers"
  type        = string
  default     = "r6gd.2xlarge"
}

variable "streaming_max_workers" {
  description = "Maximum autoscaled workers for the streaming pipeline cluster policy"
  type        = number
  default     = 4
}

variable "batch_node_type" {
  description = "Node type for spot-backed batch jobs (identity resolution, measurement, clean-room contribution)"
  type        = string
  default     = "r6gd.2xlarge"
}

variable "batch_max_workers" {
  description = "Maximum autoscaled workers for batch job clusters"
  type        = number
  default     = 8
}

variable "spot_bid_price_percent" {
  description = "Spot bid price as a percentage of on-demand price for batch job clusters"
  type        = number
  default     = 100
}

variable "databricks_runtime_version" {
  description = "Databricks Runtime (DBR) version string for cluster policies"
  type        = string
  default     = "15.4.x-photon-scala2.12"
}

variable "tags" {
  description = "Common resource tags, applied as Databricks cluster custom_tags"
  type        = map(string)
  default     = {}
}
