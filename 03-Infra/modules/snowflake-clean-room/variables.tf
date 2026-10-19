variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "snowflake_account_region" {
  description = "Snowflake account region, e.g. aws_us_east_1 - must match the partner account's region for the clean-room link to work"
  type        = string
}

variable "databricks_iceberg_rest_catalog_uri" {
  description = "Unity Catalog Iceberg REST Catalog endpoint URI (from the Databricks workspace, e.g. https://<workspace-host>/api/2.1/unity-catalog/iceberg-rest)"
  type        = string
}

variable "databricks_oauth_client_id" {
  description = "OAuth client ID issued to the Snowflake catalog integration service principal (from the databricks-external-sharing module)"
  type        = string
}

variable "databricks_oauth_client_secret" {
  description = "OAuth client secret issued to the Snowflake catalog integration service principal"
  type        = string
  sensitive   = true
}

variable "clean_room_contribution_catalog_name" {
  description = "Unity Catalog catalog name holding the clean-room contribution tables, used as the Iceberg namespace root"
  type        = string
}

variable "dcr_application_warehouse_size" {
  description = "Warehouse size for the Collaboration Data Clean Room application warehouse"
  type        = string
  default     = "XSMALL"
}

variable "dcr_analysis_warehouse_size" {
  description = "Warehouse size for ad hoc clean-room analysis queries"
  type        = string
  default     = "XSMALL"
}

variable "dcr_warehouse_auto_suspend_seconds" {
  description = "Seconds of inactivity before the DCR warehouses auto-suspend"
  type        = number
  default     = 60
}

variable "monthly_credit_quota" {
  description = "Monthly credit quota enforced by the resource monitor attached to both DCR warehouses"
  type        = number
  default     = 100
}

variable "tags" {
  description = "Common resource tags (applied as Snowflake object tags where supported)"
  type        = map(string)
  default     = {}
}
