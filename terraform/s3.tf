// This is the bucket where Airflow will place the logs from the containers that are created for every task in an Airflow DAG
resource "aws_s3_bucket_public_access_block" "deny_public_access_airflow_logs" {
  bucket                  = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-airflow-logs-${var.environment}"
  acl    = "private"

  tags = {
    Terraform   = "true"
    Project     = var.project_name
    Environment = var.environment
  }
}
