terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.9.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}
variable "aws_region" {}
variable "cloudflare_api_token" {}
provider "aws" {
  region = var.aws_region
}
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
