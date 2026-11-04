resource "aws_kinesis_stream" "ad_server_events_stream" {
  count            = var.create_stream ? 1 : 0
  name             = "${var.name_prefix}-ad-server-events"
  retention_period = var.retention_period_hours

  stream_mode_details {
    stream_mode = var.stream_mode
  }

  shard_count = var.stream_mode == "PROVISIONED" ? var.shard_count : null

  tags = merge(var.tags, { Name = "${var.name_prefix}-ad-server-events" })
}

data "aws_kinesis_stream" "existing_ad_server_events_stream" {
  count = var.create_stream ? 0 : 1
  name  = var.existing_stream_name
}

locals {
  stream_name = var.create_stream ? aws_kinesis_stream.ad_server_events_stream[0].name : data.aws_kinesis_stream.existing_ad_server_events_stream[0].name
  stream_arn  = var.create_stream ? aws_kinesis_stream.ad_server_events_stream[0].arn : data.aws_kinesis_stream.existing_ad_server_events_stream[0].arn
}
