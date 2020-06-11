variable "project_name" {}

variable "environment" {
  default = "dev"
}

variable "aws_profile" {}

variable "aws_region" {}

// This will be the ip that will be allowed to connect to Airflow and to the monitoring services by default
variable "allowed_ip" {}

variable "nodes_instance_type_1" {}

variable "nodes_instance_type_2" {}

// This RDS Postgres is used by Airflow to store metadata
variable "postgres_user" {}

variable "postgres_password" {}
