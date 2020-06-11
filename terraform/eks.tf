resource "aws_security_group" "allowed_ips" {
  name = "${var.project_name}-airflow-allowed-ips-${var.environment}"
  vpc_id        = module.vpc.vpc_id

  ingress {
    from_port   = 32000
    to_port     = 32000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "node_autoscaling_pol_doc" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]

    effect = "Allow"

    resources = [
      "*"]
  }
}

resource "aws_security_group" "worker_management" {
  name          = "${var.project_name}-airflow-worker-management-${var.environment}"
  vpc_id        = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16"
    ]
  }
}

resource "aws_iam_role" "fargate" {
  name = "${var.project_name}-fargate-${var.environment}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node_autoscaling" {
  role = module.eks_cluster.worker_iam_role_name
  policy_arn = aws_iam_policy.node_autoscaling_pol.arn
}

resource "aws_iam_policy" "node_autoscaling_pol" {
  name = "${var.project_name}-node-autoscaling-${var.environment}"
  policy = data.aws_iam_policy_document.node_autoscaling_pol_doc.json
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate.name
}

module "eks_cluster" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "12.0.0"
  cluster_name    = "${var.project_name}-airflow-${var.environment}"
  cluster_version = "1.16"
  vpc_id          = module.vpc.vpc_id
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  enable_irsa     = true

  subnets = [
    module.vpc.public_subnets[0],
    module.vpc.public_subnets[1],
    module.vpc.public_subnets[2]
  ]

  worker_additional_security_group_ids = [
    aws_security_group.worker_management.id,
    aws_security_group.allowed_ips.id
  ]

  worker_groups = [
    {
      instance_type = var.nodes_instance_type_1
      asg_max_size  = 1
      name          = "${var.project_name}-airflow-small-${var.environment}"
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "${var.project_name}-airflow-${var.environment}"
          "propagate_at_launch" = "false"
          "value"               = "true"
          "k8s.io/cluster-autoscaler/${var.project_name}-airflow-${var.environment}" = "owned"
          "k8s.io/cluster-autoscaler/enabled" = "true"
        }
      ]
    },
    {
      instance_type = var.nodes_instance_type_2
      asg_max_size  = 1
      name          = "${var.project_name}-airflow-large-${var.environment}"
      tags = [
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "propagate_at_launch" = "false"
          "value"               = "true"
        },
        {
          "key"                 = "${var.project_name}-airflow-${var.environment}"
          "propagate_at_launch" = "false"
          "value"               = "true"
          "k8s.io/cluster-autoscaler/${var.project_name}-airflow-${var.environment}" = "owned"
          "k8s.io/cluster-autoscaler/enabled" = "true"
        }
      ]
    }
  ]

  tags = {
    Terraform   = "true"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_eks_fargate_profile" "airflow" {
  cluster_name           = module.eks_cluster.cluster_id
  fargate_profile_name   = "${var.project_name}-airflow-${var.environment}"
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = module.vpc.private_subnets[*]

  selector {
    namespace = "fargate"
  }

  tags = {
    Terraform   = "true"
    Project     = var.project_name
    Environment = var.environment
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "random" {}
provider "local" {}
provider "null" {}
provider "template" {}

data "aws_availability_zones" "available" {}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_id
}

data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_id
}
