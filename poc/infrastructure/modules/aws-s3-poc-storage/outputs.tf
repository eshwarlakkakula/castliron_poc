output "bucket_name" {
  description = "Name of the Unity Catalog storage bucket"
  value       = aws_s3_bucket.unity_catalog_storage.id
}

output "bucket_arn" {
  description = "ARN of the Unity Catalog storage bucket"
  value       = aws_s3_bucket.unity_catalog_storage.arn
}
