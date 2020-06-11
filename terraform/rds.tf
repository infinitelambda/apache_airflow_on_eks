// Used by Airflow to store metadata
resource "aws_db_instance" "airflow" {
  name                  = "airflow"
  identifier            = "${var.project_name}-airflow-${var.environment}"
  username              = var.postgres_user
  password              = var.postgres_password

  storage_type          = "gp2"
  engine                = "postgres"
  engine_version        = "11.5"
  instance_class        = "db.t2.small"

  allocated_storage     = 10
  max_allocated_storage = 20

  db_subnet_group_name  = aws_db_subnet_group.private.id
  skip_final_snapshot   = true

  tags = {
    Terraform   = "true"
    Project     = var.project_name
    Environment = var.environment
  }
}
