# L1 AWS foundation - storage
# The lakehouse S3 bucket (Delta bronze/silver/gold, plus the resident
# identity-graph landing zone), encrypted with the lakehouse CMK, versioned,
# and with public access fully blocked.

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_s3_bucket" "lakehouse_data_bucket" {
  bucket = "${var.name_prefix}-lakehouse-data"
  tags   = merge(var.tags, { Name = "${var.name_prefix}-lakehouse-data" })
}

resource "aws_s3_bucket_versioning" "lakehouse_data_bucket_versioning" {
  bucket = aws_s3_bucket.lakehouse_data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lakehouse_data_bucket_encryption" {
  bucket = aws_s3_bucket.lakehouse_data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.lakehouse_kms_key_arn
    }
    bucket_key_enabled = var.enable_bucket_key
  }
}

resource "aws_s3_bucket_public_access_block" "lakehouse_data_bucket_block_public" {
  bucket                  = aws_s3_bucket.lakehouse_data_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lakehouse_data_bucket_lifecycle" {
  bucket = aws_s3_bucket.lakehouse_data_bucket.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  dynamic "rule" {
    for_each = var.bronze_transition_to_standard_ia_days > 0 ? [1] : []
    content {
      id     = "transition-bronze-to-standard-ia"
      status = "Enabled"
      filter {
        prefix = "bronze/"
      }
      transition {
        days          = var.bronze_transition_to_standard_ia_days
        storage_class = "STANDARD_IA"
      }
    }
  }
}

# S3 event notifications for Auto Loader file-notification mode (as an
# alternative to directory-listing mode) can be added here as an
# aws_s3_bucket_notification resource once that ingest decision is made.
