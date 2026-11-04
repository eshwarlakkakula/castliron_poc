data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "databricks_kinesis_instance_profile_role" {
  name               = "${var.name_prefix}-databricks-kinesis-instance-profile"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags               = var.tags
}

data "aws_iam_policy_document" "kinesis_read" {
  statement {
    sid    = "KinesisStreamRead"
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream", "kinesis:DescribeStreamSummary", "kinesis:GetRecords",
      "kinesis:GetShardIterator", "kinesis:ListShards", "kinesis:ListStreams",
      "kinesis:SubscribeToShard", "kinesis:RegisterStreamConsumer", "kinesis:DescribeStreamConsumer",
    ]
    resources = [var.kinesis_stream_arn, "${var.kinesis_stream_arn}/*"]
  }
}

resource "aws_iam_role_policy" "kinesis_read" {
  name   = "${var.name_prefix}-kinesis-read"
  role   = aws_iam_role.databricks_kinesis_instance_profile_role.id
  policy = data.aws_iam_policy_document.kinesis_read.json
}

resource "aws_iam_instance_profile" "databricks_kinesis" {
  name = "${var.name_prefix}-databricks-kinesis-instance-profile"
  role = aws_iam_role.databricks_kinesis_instance_profile_role.name
}
