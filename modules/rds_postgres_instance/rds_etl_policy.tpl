{
  "Statement": [
    {
      "Sid": "s3import",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${data_lake_s3_bucket_name}",
        "arn:aws:s3:::${data_lake_s3_bucket_name}/*"
      ]
    }
  ],
  "Version": "2012-10-17"
}