provider "aws" {
  profile             = var.aws_profile
  region              = var.aws_region
}

// This will generate a file with an S3 backend defined in it. The advantage of using this is that we can use variables here.
// Make sure that Terraform moves your state file to the bucket, and that the state file is not stored locally instead.
resource "local_file" "backend_file" {
  content = data.template_file.backend_tf.rendered
  filename = "backend.tf"
}

data "template_file" "backend_tf" {
  template = <<POLICY
 terraform {
     backend "s3" {
       bucket         = "$${bucket}"
       key            = "$${key}"
       region         = "$${region}"
   }
 }
POLICY
   vars = {
     bucket = "${var.project_name}-terraform-state-${var.environment}"
     key = "${var.environment}/terraform.tfstate"
     region = var.aws_region
   }
}
