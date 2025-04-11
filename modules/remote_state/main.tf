locals {
  tags = merge(var.tags, {
    Terraform = true
  })
}

# ------------------------------------------------------------------------------
# S3 BUCKET
# ------------------------------------------------------------------------------

module "s3_bucket" {
  source = "../s3_bucket"

  bucket_name_suffix = var.s3_bucket_suffix

  enable_archive = false

  tags = local.tags
}

# ------------------------------------------------------------------------------
# DYNAMODB TABLE
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
