variable "project_name" {
  description = "Short project identifier used in resource names"
  type        = string
  default     = "castiron-lakehouse"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "Availability zones for the lakehouse VPC"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr_block" {
  description = "CIDR block for the lakehouse VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "private_subnet_cidr_blocks" {
  description = "Private subnet CIDR blocks, one per availability zone"
  type        = list(string)
  default     = ["10.20.0.0/20", "10.20.16.0/20"]
}

variable "public_subnet_cidr_blocks" {
  description = "Public subnet CIDR blocks, one per availability zone"
  type        = list(string)
  default     = ["10.20.32.0/24", "10.20.33.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway to control dev cost"
  type        = bool
  default     = true
}

variable "key_administrator_arns" {
  description = "IAM principal ARNs allowed full administrative control of the lakehouse CMK"
  type        = list(string)
}

variable "key_user_arns" {
  description = "Additional IAM principal ARNs allowed to use the lakehouse CMK, beyond the Databricks roles this stack creates"
  type        = list(string)
  default     = []
}

variable "databricks_account_id" {
  description = "Databricks account ID (UUID), used in the cross-account trust policy"
  type        = string
}

variable "create_kinesis_stream" {
  description = "Create a new Kinesis stream for this environment (true for production/POC)"
  type        = bool
  default     = true
}

variable "kinesis_shard_count" {
  description = "Provisioned shard count for the Kinesis stream"
  type        = number
  default     = 4
}

variable "tags" {
  description = "Common resource tags applied across this layer"
  type        = map(string)
  default = {
    Project     = "castiron-lakehouse"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
