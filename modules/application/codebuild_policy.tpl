{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowECR",
            "Effect": "Allow",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:UploadLayerPart",
                "ecr:PutImage",
                "ecr:BatchGetImage",
                "ecr:CompleteLayerUpload",
                "ecr:InitiateLayerUpload",
                "ecr:BatchCheckLayerAvailability"
            ],
            "Resource": [
                "${ecr_arn}"
            ]
        },
        {
            "Sid": "AllowECRAuthorizationToken",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowS3",
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketAcl",
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetBucketLocation",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::${code_pipeline_s3_bucket_name}",
                "arn:aws:s3:::${code_pipeline_s3_bucket_name}/*"
            ]
        },
        {
            "Sid": "AllowCodebuildReportGroup",
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutCodeCoverages",
                "codebuild:BatchPutTestCases"
            ],
            "Resource": [
                "arn:aws:codebuild:us-east-1:924586450630:report-group/${codebuild_project_name}-*"
            ]
        },
        {
            "Sid": "AllowLogs",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:PutLogEvents",
                "logs:CreateLogStream"
            ],
            "Resource": [
                "arn:aws:logs:us-east-1:924586450630:log-group:/aws/codebuild/${codebuild_project_name}",
                "arn:aws:logs:us-east-1:924586450630:log-group:/aws/codebuild/${codebuild_project_name}:*"
            ]
        }
    ]
}