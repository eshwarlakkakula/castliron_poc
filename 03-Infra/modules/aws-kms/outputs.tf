output "lakehouse_data_key_arn" {
  description = "ARN of the lakehouse data encryption key"
  value       = aws_kms_key.lakehouse_data_key.arn
}

output "lakehouse_data_key_id" {
  description = "Key ID of the lakehouse data encryption key"
  value       = aws_kms_key.lakehouse_data_key.key_id
}

output "lakehouse_data_key_alias_name" {
  description = "Alias name of the lakehouse data encryption key"
  value       = aws_kms_alias.lakehouse_data_key_alias.name
}
