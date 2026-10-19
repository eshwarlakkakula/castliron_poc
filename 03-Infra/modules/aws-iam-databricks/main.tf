# L1 AWS foundation - Databricks cross-account access
# The cross-account IAM role Databricks assumes to manage compute in this
# account (per Databricks' documented cross-account role pattern), plus an
# instance profile scoped to exactly the lakehouse bucket, the lakehouse
# KMS key, and the Kinesis stream - not account-wide S3/KMS/Kinesis access.

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  # Documented Databricks control-plane account ID for cross-account role trust.
  databricks_control_plane_account_id = "414351767826"
}

data "aws_iam_policy_document" "databricks_cross_account_trust_policy" {
  statement {
    sid     = "DatabricksCrossAccountAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.databricks_control_plane_account_id}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.databricks_account_id]
    }
  }
}

resource "aws_iam_role" "databricks_cross_account_role" {
  name               = "${var.name_prefix}-databricks-cross-account-role"
  assume_role_policy = data.aws_iam_policy_document.databricks_cross_account_trust_policy.json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-databricks-cross-account-role" })
}

data "aws_iam_policy_document" "databricks_cross_account_compute_policy" {
  statement {
    sid    = "DatabricksEc2ComputeManagement"
    effect = "Allow"
    actions = [
      "ec2:RunInstances", "ec2:TerminateInstances", "ec2:DescribeInstances",
      "ec2:CreateTags", "ec2:DeleteTags", "ec2:DescribeTags",
      "ec2:CreateSecurityGroup", "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress", "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets", "ec2:DescribeVpcs", "ec2:DescribeAvailabilityZones",
      "ec2:CreateVolume", "ec2:DeleteVolume", "ec2:AttachVolume", "ec2:DetachVolume", "ec2:DescribeVolumes",
      "ec2:RequestSpotInstances", "ec2:DescribeSpotInstanceRequests", "ec2:CancelSpotInstanceRequests",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "DatabricksPassComputeRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.databricks_compute_instance_role.arn]
  }
}

resource "aws_iam_role_policy" "databricks_cross_account_compute" {
  name   = "${var.name_prefix}-databricks-compute-management"
  role   = aws_iam_role.databricks_cross_account_role.id
  policy = data.aws_iam_policy_document.databricks_cross_account_compute_policy.json
}

# ---------------------------------------------------------------- compute instance profile
data "aws_iam_policy_document" "databricks_compute_instance_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "databricks_compute_instance_role" {
  name               = "${var.name_prefix}-databricks-compute-instance-role"
  assume_role_policy = data.aws_iam_policy_document.databricks_compute_instance_trust_policy.json
  tags               = merge(var.tags, { Name = "${var.name_prefix}-databricks-compute-instance-role" })
}

data "aws_iam_policy_document" "databricks_compute_instance_data_policy" {
  statement {
    sid    = "LakehouseBucketReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket", "s3:GetBucketLocation",
    ]
    resources = [
      var.lakehouse_data_bucket_arn,
      "${var.lakehouse_data_bucket_arn}/*",
    ]
  }

  statement {
    sid       = "LakehouseKeyUse"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [var.lakehouse_kms_key_arn]
  }

  statement {
    sid    = "KinesisConsumeStream"
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream", "kinesis:DescribeStreamSummary", "kinesis:GetRecords",
      "kinesis:GetShardIterator", "kinesis:ListShards", "kinesis:SubscribeToShard",
      "kinesis:DescribeStreamConsumer", "kinesis:RegisterStreamConsumer",
    ]
    resources = [var.kinesis_stream_arn, "${var.kinesis_stream_arn}/*"]
  }
}

resource "aws_iam_role_policy" "databricks_compute_instance_data_access" {
  name   = "${var.name_prefix}-databricks-compute-data-access"
  role   = aws_iam_role.databricks_compute_instance_role.id
  policy = data.aws_iam_policy_document.databricks_compute_instance_data_policy.json
}

resource "aws_iam_instance_profile" "databricks_compute_instance_profile" {
  name = "${var.name_prefix}-databricks-compute-instance-profile"
  role = aws_iam_role.databricks_compute_instance_role.name
  tags = merge(var.tags, { Name = "${var.name_prefix}-databricks-compute-instance-profile" })
}
