{
    "Statement": [
        {
            "Sid": "AllowSSMDescribeParameters",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowSSMGetParameters",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter",
                "ssm:GetParameters"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/${name}/*"
        }
    ],
    "Version": "2012-10-17"
}