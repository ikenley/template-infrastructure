
data "aws_ses_email_identity" "ses_email_address" {
  email = var.ses_email_address
}