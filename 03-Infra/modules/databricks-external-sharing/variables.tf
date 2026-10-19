variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "clean_room_contribution_catalog_name" {
  description = "Catalog that holds the clean-room contribution tables (Delta + UniForm) to expose read-only via Iceberg REST"
  type        = string
}

variable "clean_room_contribution_schema_name" {
  description = "Schema within the catalog that holds the clean-room contribution tables"
  type        = string
  default     = "clean_room_contribution"
}

variable "oauth_token_lifetime_seconds" {
  description = "Lifetime of OAuth tokens issued to the Snowflake catalog integration service principal"
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
