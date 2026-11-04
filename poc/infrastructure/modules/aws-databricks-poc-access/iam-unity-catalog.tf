data "aws_iam_policy_document" "unity_catalog_trust" {
  statement {
    sid     = "DatabricksUnityCatalogAssume"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [var.databricks_unity_catalog_principal_arn != "" ? var.databricks_unity_catalog_principal_arn : data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.databricks_external_id]
    }
  }
  statement {
    sid     = "SelfAssumeForCredentialVending"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-unity-catalog-storage-credential"]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "unity_catalog_storage_role" {
  name               = "${var.name_prefix}-unity-catalog-storage-credential"
  assume_role_policy = data.aws_iam_policy_document.unity_catalog_trust.json
  tags               = var.tags
}

data "aws_iam_policy_document" "unity_catalog_storage_access" {
  statement {
    sid       = "UnityCatalogBucketAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket", "s3:GetBucketLocation"]
    resources = [var.unity_catalog_storage_bucket_arn, "${var.unity_catalog_storage_bucket_arn}/*"]
  }
  statement {
    sid       = "UnityCatalogAssumeOwnRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.unity_catalog_storage_role.arn]
  }
}

resource "aws_iam_role_policy" "unity_catalog_storage_access" {
  name   = "${var.name_prefix}-unity-catalog-storage-access"
  role   = aws_iam_role.unity_catalog_storage_role.id
  policy = data.aws_iam_policy_document.unity_catalog_storage_access.json
}
