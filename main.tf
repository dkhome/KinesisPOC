provider "aws" {
  region = "us-west-1"
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
  bucket = "kinesis-stream-bucket-for-poc"
  acl    = "private"

  tags =  var.tags[local.env_name]
}

resource "aws_kinesis_stream" "kinesis_stream" {
  name             = "kinesis-stream"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags =  var.tags[local.env_name]
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
}

resource "aws_iam_role_policy" "kinesis_policy" {
  name = "kinesis_policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:DescribeStream",
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
      role_arn = aws_iam_role.firehose_role.arn
  }

  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.kinesis_bucket.arn
  }

  tags =  var.tags[local.env_name]
}
