output "vpc_id" {
  description = "ID of the lakehouse VPC"
  value       = aws_vpc.lakehouse_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the lakehouse VPC"
  value       = aws_vpc.lakehouse_vpc.cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs, for Databricks classic compute and the Kinesis consumer"
  value       = aws_subnet.private_subnets[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (NAT gateways only)"
  value       = aws_subnet.public_subnets[*].id
}

output "private_route_table_ids" {
  description = "Private route table IDs, for downstream modules that need to add routes"
  value       = aws_route_table.private_route_tables[*].id
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID attached to the interface VPC endpoints"
  value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints_security_group[0].id : null
}
