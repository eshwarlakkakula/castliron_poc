output "cluster_endpoint" {
  description = "Writer endpoint for the Aurora MySQL cluster"
  value       = aws_rds_cluster.poc.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the Aurora MySQL cluster"
  value       = aws_rds_cluster.poc.reader_endpoint
}

output "port" {
  description = "Port the cluster listens on"
  value       = aws_rds_cluster.poc.port
}

output "database_name" {
  description = "Initial database name on the cluster"
  value       = aws_rds_cluster.poc.database_name
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN holding the master user credentials (AWS-managed)"
  value       = aws_rds_cluster.poc.master_user_secret[0].secret_arn
}
