terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

    backend "s3" {
    bucket         = "taskflow-terraform-state-221792772427"
    key            = "taskflow/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}


provider "aws" {
  region = var.region
}

