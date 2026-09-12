terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "toggle-master-terraform-state-325898365409"
    key          = "toggle-master/staging/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { Project = "toggle-master", Environment = var.environment, ManagedBy = "terraform" } }
}

data "aws_availability_zones" "available" { state = "available" }
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_role" "academy_lab" {
  count = var.academy_mode ? 1 : 0
  name  = var.lab_role_name
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" { name = aws_eks_cluster.this.name }
