# L1 AWS foundation - KMS
# Customer-managed key for lakehouse S3 (bronze/silver/gold), Secrets
# Manager, and the identity-graph landing zone. Separate from the L0
# Terraform-state key so a lakehouse key rotation or policy change can never
# touch state encryption.

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lakehouse_kms_key_policy" {
  statement {
    sid       = "EnableRootAccountPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowKeyAdministration"
    effect    = "Allow"
    actions   = ["kms:Create*", "kms:Describe*", "kms:Enable*", "kms:List*", "kms:Put*", "kms:Update*", "kms:Revoke*", "kms:Disable*", "kms:Get*", "kms:Delete*", "kms:TagResource", "kms:UntagResource", "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = var.key_administrator_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.key_user_arns) > 0 ? [1] : []
    content {
      sid       = "AllowKeyUsage"
      effect    = "Allow"
      actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = var.key_user_arns
      }
    }
  }
}

resource "aws_kms_key" "lakehouse_data_key" {
  description             = "${var.name_prefix} lakehouse data encryption key (S3, Secrets Manager, identity graph)"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  policy                  = data.aws_iam_policy_document.lakehouse_kms_key_policy.json
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-lakehouse-data-key" })
}

resource "aws_kms_alias" "lakehouse_data_key_alias" {
  name          = "alias/${var.name_prefix}-lakehouse-data"
  target_key_id = aws_kms_key.lakehouse_data_key.key_id
}
