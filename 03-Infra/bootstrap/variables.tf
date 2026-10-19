variable "project_name" {
  description = "Short project identifier used in resource names, e.g. castiron-lakehouse"
  type        = string
}

variable "environment" {
  description = "Set to \"shared\" - this bootstrap stack is applied once and its state bucket/lock table/CI role serve every environment (dev, staging, production), distinguished by state key prefix, not by separate buckets. Not meant to vary per environment."
  type        = string
  default     = "shared"
}

variable "aws_region" {
  description = "AWS region for the state bucket, lock table, and CI OIDC provider"
  type        = string
  default     = "us-east-1"
}

variable "github_organization" {
  description = "GitHub organization or user that owns the repository allowed to assume the CI role"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name (without the org prefix) allowed to assume the CI role"
  type        = string
}

variable "github_allowed_refs" {
  description = "Git refs allowed to assume the CI deployment role, e.g. [\"refs/heads/main\", \"refs/heads/develop\"]"
  type        = list(string)
  default     = ["refs/heads/main"]
}

variable "tags" {
  description = "Common resource tags applied to every bootstrap resource"
  type        = map(string)
  default     = {}
}
