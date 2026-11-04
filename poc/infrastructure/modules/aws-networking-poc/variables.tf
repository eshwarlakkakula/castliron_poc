variable "name_prefix" {
  description = "Prefix applied to every resource name in this module"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the POC VPC"
  type        = string
  default     = "10.60.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per availability zone (minimum 2, required by the Aurora DB subnet group)"
  type        = list(string)
  default     = ["10.60.1.0/24", "10.60.2.0/24"]
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 subnet CIDRs are required for the Aurora DB subnet group."
  }
}

variable "ingress_rules" {
  description = "Ingress rules applied to the shared security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    cidr_blocks = list(string)
  }))
  validation {
    condition     = alltrue([for rule in var.ingress_rules : length(rule.cidr_blocks) > 0])
    error_message = "Every ingress rule must list at least one CIDR block."
  }
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
