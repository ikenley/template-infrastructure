data "aws_caller_identity" "current" {}

locals {
  tags = merge(var.tags, {
    Terraform = true
  })
  account_id = data.aws_caller_identity.current.account_id
  bucket_name = "${local.account_id}-${var.bucket_name_suffix}"
}

# ------------------------------------------------------------------------------
# A private S3 bucket
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.kms_alias == "" ? "" : aws_kms_key.this[0].arn
        sse_algorithm     = var.kms_alias == "" ? "AES256" : "aws:kms"
      }
    }
  }

  tags = local.tags
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy != "" ? var.bucket_policy : templatefile("${path.module}/bucket_policy.tmpl", {
    bucket_name = local.bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "this" {
  count = var.kms_alias == "" ? 0 : 1
  
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation = true
}

resource "aws_kms_alias" "this" {
  count = var.kms_alias == "" ? 0 : 1

  name          = "alias/${var.kms_alias}"
  target_key_id = aws_kms_key.this[0].key_id
}