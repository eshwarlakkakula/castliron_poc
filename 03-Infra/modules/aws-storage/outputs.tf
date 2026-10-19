output "lakehouse_data_bucket_name" {
  description = "Name of the lakehouse S3 bucket"
  value       = aws_s3_bucket.lakehouse_data_bucket.bucket
}

output "lakehouse_data_bucket_arn" {
  description = "ARN of the lakehouse S3 bucket"
  value       = aws_s3_bucket.lakehouse_data_bucket.arn
}

output "identity_graph_prefix" {
  description = "Prefix reserved for the resident identity-graph landing zone"
  value       = var.identity_graph_prefix
}
