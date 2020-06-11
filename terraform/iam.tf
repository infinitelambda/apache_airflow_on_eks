// This IAM User is created for Airflow to use when putting logs into the Logs S3 Bucket
resource "aws_iam_access_key" "airflow_logs" {
  user    = aws_iam_user.airflow_logs.name
}

resource "aws_iam_user" "airflow_logs" {
  name = "${var.project_name}-airflow-logs-${var.environment}"
}

resource "aws_iam_user_policy" "airflow_logs" {
  name = "airlfow-logs"
  user = aws_iam_user.airflow_logs.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
