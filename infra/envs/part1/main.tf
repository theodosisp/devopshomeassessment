terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "cdn" {
  source = "../../modules/cdn"

  bucket_name = var.bucket_name

  tags = {
    Project = "devops-assessment"
    Part    = "1-cdn"
  }
}
