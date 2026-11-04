resource "aws_kinesis_stream_consumer" "lakeflow_enhanced_fan_out_consumer" {
  name       = var.enhanced_fan_out_consumer_name
  stream_arn = local.stream_arn
}
