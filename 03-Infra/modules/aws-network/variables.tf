variable "name_prefix" {
  description = "Prefix applied to every resource name in this module, e.g. castiron-lakehouse-dev"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the lakehouse VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread subnets and NAT gateways across"
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "CIDR blocks for the private subnets (Databricks classic compute, Kinesis consumer), one per availability zone"
  type        = list(string)
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks for the public subnets (NAT gateways only), one per availability zone"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway instead of one per AZ. True for dev/POC to control cost, false for staging/production."
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Create interface/gateway VPC endpoints (S3, STS, Kinesis, Secrets Manager) to keep bulk data off the NAT path"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
