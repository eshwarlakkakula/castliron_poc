variable "project_name" {
  type    = string
  default = "castiron-lakehouse"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "streaming_max_workers" {
  type    = number
  default = 4
}

variable "batch_max_workers" {
  type    = number
  default = 8
}

variable "databricks_runtime_version" {
  type    = string
  default = "15.4.x-photon-scala2.12"
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "castiron-lakehouse"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
