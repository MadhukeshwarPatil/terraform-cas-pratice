# Root Provider Configuration
# This file contains the global provider settings

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
# Configure the AWS Provider
# provider "aws" {
#   region = "us-west-2"
#   
#   default_tags {
#     tags = {
#       ManagedBy = "terraform"
#       Project   = "terraform-cas-practice"
#     }
#   }
# }
