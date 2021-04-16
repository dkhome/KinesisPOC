provider "aws" {
  region = var.location[local.env_name]
}

resource "aws_resourcegroups_group" "kinesis_poc_resources" {
  name = "kinesis-poc-resources"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": ["AWS::AllSupported"],
  "TagFilters": [
    {
      "Key": "Project",
      "Values": ["KinesisPOC"]
    }
  ]
}
JSON
  }
}

resource "aws_s3_bucket" "kinesis_bucket" {
  bucket        = "kinesis-stream-bucket-for-poc-${var.location[local.env_name]}"
  acl           = "private"
  force_destroy = true
  tags          = var.tags[local.env_name]
}

resource "aws_kinesis_stream" "kinesis_stream" {
  name             = "kinesis-stream"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags = var.tags[local.env_name]
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_kinesis_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  managed_policy_arns = [aws_iam_policy.policy_s3_kinesis.arn]
}

resource "aws_iam_policy" "policy_s3_kinesis" {
  name = "policy-s3-kinesis"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["kinesis:DescribeStream", "kinesis:GetRecords", "kinesis:GetShardIterator",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:AbortMultipartUpload",
            "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_kinesis_firehose_delivery_stream" "firehose_delivery_stream" {
  name        = "kinesis-firehose-delivery-stream"
  destination = "s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kinesis_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  s3_configuration {
    role_arn        = aws_iam_role.firehose_role.arn
    bucket_arn      = aws_s3_bucket.kinesis_bucket.arn
    buffer_size     = 1
    buffer_interval = 60
  }

  tags = var.tags[local.env_name]
}
