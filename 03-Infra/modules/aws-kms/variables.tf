variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "key_administrator_arns" {
  description = "IAM principal ARNs allowed full administrative control of the lakehouse CMK"
  type        = list(string)
}

variable "key_user_arns" {
  description = "IAM principal ARNs allowed to encrypt/decrypt with the lakehouse CMK (Databricks cross-account role, CI role)"
  type        = list(string)
  default     = []
}

variable "deletion_window_in_days" {
  description = "KMS key deletion window"
  type        = number
  default     = 30
}

variable "enable_key_rotation" {
  description = "Enable automatic annual key rotation"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
