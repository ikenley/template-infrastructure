output "s3_bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "The ARN of the S3 bucket"
}

output "s3_bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "The id of the S3 bucket"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.this.id
  description = "The id of the S3 bucket"
}
