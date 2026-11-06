terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.59.0"
    }
  }

  # Configure remote backend
  backend "s3" {
    bucket         = "my-terraform-state-bucket-480227945624"
    key            = "voting-app/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}