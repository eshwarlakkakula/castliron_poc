variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "lakehouse_kms_key_arn" {
  description = "KMS key ARN used to encrypt the lakehouse bucket (from the aws-kms module)"
  type        = string
}

variable "enable_bucket_key" {
  description = "Enable S3 Bucket Keys to reduce KMS request volume and cost"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days before a noncurrent (overwritten/deleted) object version is permanently expired"
  type        = number
  default     = 90
}

variable "bronze_transition_to_standard_ia_days" {
  description = "Days before bronze objects transition to S3 Standard-IA (0 to disable)"
  type        = number
  default     = 60
}

variable "identity_graph_prefix" {
  description = "Prefix under the lakehouse bucket reserved for the resident identity graph landing zone"
  type        = string
  default     = "identity-graph/"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
