#------------------------------------------------------------------------------
# Create IAM OIDC identity provider and Role for GitHub
# Allows GitHub Actions to use AWS commands
# Based on https://github.com/unfunco/terraform-aws-oidc-github/tree/main
#------------------------------------------------------------------------------

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {

  client_id_list = concat(
    ["https://github.com/${var.github_org}"],
    ["sts.amazonaws.com"]
  )

  tags = var.tags
  url  = "https://token.actions.githubusercontent.com"
  thumbprint_list = toset(
    concat(
      [data.tls_certificate.github.certificates[0].sha1_fingerprint]
    )
  )
}

resource "aws_iam_role" "github" {
  name = "${local.id}-github"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.git_hub_assume_role.json
  description        = "Role assumed by the GitHub OIDC provider."

  tags = local.tags
}

data "aws_iam_policy_document" "git_hub_assume_role" {

  version = "2012-10-17"

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"


    principals {
      identifiers = ["${aws_iam_openid_connect_provider.github.arn}"]
      type        = "Federated"
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

  }
}

# Add additional policy permissions
resource "aws_iam_role_policy_attachment" "github_code_artifact" {
  role       = aws_iam_role.github.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeArtifactReadOnlyAccess"
}