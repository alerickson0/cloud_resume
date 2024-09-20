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

  required_version = "~> 1.5.7"
}

provider "aws" {
  # Configuration options
  region = var.region
}

