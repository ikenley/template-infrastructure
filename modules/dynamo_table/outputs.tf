output "dynamo_policy_arn" {
  description = "Read/write access to OTC Dynamo table"
  value       = aws_iam_policy.dynamo_policy.arn
}

output "table_name" {
  value = aws_dynamodb_table.this.name
}
