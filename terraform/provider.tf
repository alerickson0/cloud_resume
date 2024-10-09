terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.46.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }

  backend "s3" {
    bucket = "terraform-state-remote-back-end"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
  }

  required_version = "~> 1.5.7"
}

provider "aws" {
  # Configuration options
  region = var.region
}

