terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
  }

  backend "s3" {
    bucket  = "vmsilvamolina-state"
    key     = "eks-demo/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# Las credenciales se toman del entorno (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
# AWS_SESSION_TOKEN) o del perfil por defecto de ~/.aws/credentials.
provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
