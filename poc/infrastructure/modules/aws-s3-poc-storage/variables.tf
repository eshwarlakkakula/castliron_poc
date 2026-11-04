variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "force_destroy" {
  description = "Allow terraform destroy to delete the bucket even if it still holds objects"
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days to retain noncurrent object versions before expiry"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
