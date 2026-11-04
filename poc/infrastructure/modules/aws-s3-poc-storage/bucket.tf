resource "aws_s3_bucket" "unity_catalog_storage" {
  bucket        = "${var.name_prefix}-unity-catalog-storage"
  force_destroy = var.force_destroy
  tags          = merge(var.tags, { Name = "${var.name_prefix}-unity-catalog-storage" })
}

resource "aws_s3_bucket_versioning" "unity_catalog_storage" {
  bucket = aws_s3_bucket.unity_catalog_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "unity_catalog_storage" {
  bucket = aws_s3_bucket.unity_catalog_storage.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "unity_catalog_storage" {
  bucket                  = aws_s3_bucket.unity_catalog_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "unity_catalog_storage" {
  bucket = aws_s3_bucket.unity_catalog_storage.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}
