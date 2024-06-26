terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.46.0"
    }
  }

  required_version = "~> 1.5.7"
}

provider "aws" {
  # Configuration options
  region = var.region
}

