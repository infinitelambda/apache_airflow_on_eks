// Secret for the Logs IAM User that contains the Access Keys
resource "aws_secretsmanager_secret" "airflow_logging_user" {
  name                = "${var.project_name}-airflow-logging-user-${var.environment}"
  description         = "This is the IAM Programmatic User's access keys, that is used by Airflow to put it's container logs into a an S3 bucket"

  tags = {
    Terraform   = "true"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "airflow_logging_user" {
  secret_id     = aws_secretsmanager_secret.airflow_logging_user.id
  secret_string = <<EOT
{
  "AWS_ACCESS_KEY_ID": "${aws_iam_access_key.airflow_logs.id}",
  "AWS_SECRET_ACCESS_KEY": "${aws_iam_access_key.airflow_logs.secret}"
}
EOT
}
