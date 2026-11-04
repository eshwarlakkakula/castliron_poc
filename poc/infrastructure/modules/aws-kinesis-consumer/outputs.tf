output "stream_name" {
  description = "Name of the Kinesis stream (created or referenced)"
  value       = local.stream_name
}

output "stream_arn" {
  description = "ARN of the Kinesis stream (created or referenced)"
  value       = local.stream_arn
}

output "enhanced_fan_out_consumer_arn" {
  description = "ARN of the registered enhanced fan-out consumer, for the Lakeflow ingest pipeline configuration"
  value       = aws_kinesis_stream_consumer.lakeflow_enhanced_fan_out_consumer.arn
}
