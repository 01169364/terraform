resource "aws_s3_bucket" "source" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket" "destination" {
  bucket = var.destination_bucket_name
}

resource "aws_iam_role" "replication_role" {
  name = "s3-replication-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication_policy" {
  name = "s3-replication-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3ReplicationPolicyStmt",
      "Effect": "Allow",
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.source.arn}",
        "${aws_s3_bucket.source.arn}/*"
      ]
    },
    {
      "Sid": "S3ReplicationPolicyStmt2",
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging"
      ],
      "Resource": [
        "${aws_s3_bucket.source.arn}",
        "${aws_s3_bucket.source.arn}/*"
      ]
    },
    {
      "Sid": "S3ReplicationPolicyStmt3",
      "Effect": "Allow",
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Resource": "${aws_s3_bucket.destination.arn}/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "replication_policy_attachment" {
  role       = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

resource "aws_s3_bucket_versioning" "destination" {
  bucket = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "replicate" {
  role   = aws_iam_role.replication_role.arn
  bucket = aws_s3_bucket.destination.id
  rule {
    status = "Enabled"
    destination {
      bucket = aws_s3_bucket.destination.arn
    }
  }
}
