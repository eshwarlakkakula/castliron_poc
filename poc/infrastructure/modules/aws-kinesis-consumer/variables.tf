variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "create_stream" {
  description = "Create a new Kinesis stream (POC/dev). Set false in production, where the stream already exists and is only referenced."
  type        = bool
  default     = true
}

variable "existing_stream_name" {
  description = "Name of the existing production Kinesis stream to reference when create_stream is false"
  type        = string
  default     = ""
}

variable "shard_count" {
  description = "Provisioned shard count when stream_mode is PROVISIONED. Confirmed POC value: 4. Production value: open item, see Technical Approach Section 9 (12 assumed, ~25+ needed for the full burst target)."
  type        = number
  default     = 4
}

variable "stream_mode" {
  description = "ON_DEMAND or PROVISIONED"
  type        = string
  default     = "PROVISIONED"
  validation {
    condition     = contains(["ON_DEMAND", "PROVISIONED"], var.stream_mode)
    error_message = "stream_mode must be ON_DEMAND or PROVISIONED."
  }
}

variable "retention_period_hours" {
  description = "Kinesis stream retention period in hours"
  type        = number
  default     = 48
}

variable "enhanced_fan_out_consumer_name" {
  description = "Name of the enhanced fan-out (EFO) consumer registered for the Lakeflow ingest pipeline"
  type        = string
  default     = "lakeflow-ingest-consumer"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
