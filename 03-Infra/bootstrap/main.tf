# L0 Bootstrap
# Creates the Terraform state backend (S3 + DynamoDB lock table), the state
# encryption key, and the GitHub Actions OIDC trust that every later layer's
# CI role assumes. Applied once, manually, before any other layer. Its own
# state is local (see README.md) because nothing else exists yet to hold it.

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Layer       = "L0-bootstrap"
    ManagedBy   = "terraform"
  })
}

# ---------------------------------------------------------------- state encryption key
resource "aws_kms_key" "terraform_state_key" {
  description             = "${local.name_prefix} Terraform state encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = merge(local.common_tags, { Name = "${local.name_prefix}-terraform-state-key" })
}

resource "aws_kms_alias" "terraform_state_key_alias" {
  name          = "alias/${local.name_prefix}-terraform-state"
  target_key_id = aws_kms_key.terraform_state_key.key_id
}

# ---------------------------------------------------------------- state bucket
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "${local.name_prefix}-terraform-state"
  tags   = merge(local.common_tags, { Name = "${local.name_prefix}-terraform-state" })
}

resource "aws_s3_bucket_versioning" "terraform_state_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_bucket_encryption" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state_key.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_bucket_block_public" {
  bucket                  = aws_s3_bucket.terraform_state_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------- state lock table
resource "aws_dynamodb_table" "terraform_state_lock_table" {
  name         = "${local.name_prefix}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_state_key.arn
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-terraform-lock" })
}

# ---------------------------------------------------------------- GitHub Actions OIDC trust
resource "aws_iam_openid_connect_provider" "github_actions_oidc_provider" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = merge(local.common_tags, { Name = "${local.name_prefix}-github-actions-oidc" })
}

data "aws_iam_policy_document" "github_actions_assume_role_policy" {
  statement {
    sid     = "GitHubActionsOidcAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions_oidc_provider.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for ref in var.github_allowed_refs : "repo:${var.github_organization}/${var.github_repository}:ref:${ref}"]
    }
  }
}

resource "aws_iam_role" "terraform_ci_deployment_role" {
  name                 = "${local.name_prefix}-terraform-ci-role"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_assume_role_policy.json
  max_session_duration = 3600
  tags                 = merge(local.common_tags, { Name = "${local.name_prefix}-terraform-ci-role" })
}

data "aws_iam_policy_document" "terraform_ci_state_access_policy" {
  statement {
    sid    = "StateBucketReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.terraform_state_bucket.arn,
      "${aws_s3_bucket.terraform_state_bucket.arn}/*",
    ]
  }

  statement {
    sid       = "StateLockTableAccess"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.terraform_state_lock_table.arn]
  }

  statement {
    sid       = "StateKeyUse"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
    resources = [aws_kms_key.terraform_state_key.arn]
  }
}

resource "aws_iam_role_policy" "terraform_ci_state_access" {
  name   = "${local.name_prefix}-terraform-ci-state-access"
  role   = aws_iam_role.terraform_ci_deployment_role.id
  policy = data.aws_iam_policy_document.terraform_ci_state_access_policy.json
}

# Note: this role's state-access policy is deliberately narrow. Each
# downstream layer (L1-L5) grants the same role additional, layer-scoped
# permissions via its own IAM policy attachment, rather than widening this
# bootstrap policy — keeps blast radius per layer explicit and auditable.
