resource "aws_iam_user" "serverless_kinesis_reader" {
  name = "${var.name_prefix}-serverless-kinesis-reader"
  tags = var.tags
}

resource "aws_iam_user_policy" "serverless_kinesis_read" {
  name   = "${var.name_prefix}-serverless-kinesis-read"
  user   = aws_iam_user.serverless_kinesis_reader.name
  policy = data.aws_iam_policy_document.kinesis_read.json
}

resource "aws_iam_access_key" "serverless_kinesis_reader" {
  user = aws_iam_user.serverless_kinesis_reader.name
}
