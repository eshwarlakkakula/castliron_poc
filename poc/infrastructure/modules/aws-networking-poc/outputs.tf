output "vpc_id" {
  description = "VPC ID used for POC resources"
  value       = aws_vpc.poc.id
}

output "subnet_ids" {
  description = "Subnet IDs used for POC resources"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "db_subnet_group_name" {
  description = "DB subnet group name for RDS/Aurora resources"
  value       = aws_db_subnet_group.poc.name
}

output "security_group_id" {
  description = "Shared ingress security group ID"
  value       = aws_security_group.poc_ingress.id
}
