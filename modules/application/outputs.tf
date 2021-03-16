
output "aws_lb_lb_id" {
  description = "The ARN of the load balancer (matches arn)."
  value       = module.alb.aws_lb_lb_id
}

output "aws_lb_lb_arn" {
  description = "The ARN of the load balancer (matches id)."
  value       = module.alb.aws_lb_lb_arn
}

output "aws_lb_lb_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics."
  value       = module.alb.aws_lb_lb_arn_suffix
}

output "aws_lb_lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = module.alb.aws_lb_lb_dns_name
}

output "aws_lb_lb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record)."
  value       = module.alb.aws_lb_lb_zone_id
}

output "alb_log_s3_bucket_arn" {
  value       = module.alb.alb_log_s3_bucket_arn
  description = "The ARN of the S3 bucket"
}

output "alb_log_s3_bucket_id" {
  value       = module.alb.alb_log_s3_bucket_id
  description = "The ARN of the S3 bucket"
}
