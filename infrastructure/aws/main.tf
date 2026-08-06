# Grahvani — Terraform Root Module
# Provider configuration, remote state backend, and shared data sources.
#
# Prerequisites before first apply:
#   1. Create an S3 bucket for Terraform state:
#      aws s3api create-bucket --bucket grahvani-terraform-state \
#        --region ap-south-1 --create-bucket-configuration LocationConstraint=ap-south-1
#   2. Enable versioning: aws s3api put-bucket-versioning ...
#   3. Create DynamoDB lock table: aws dynamodb create-table \
#      --table-name grahvani-terraform-locks \
#      --attribute-definitions AttributeName=LockID,AttributeType=S \
#      --key-schema AttributeName=LockID,KeyType=HASH \
#      --billing-mode PAY_PER_REQUEST --region ap-south-1

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Remote state backend — ensures state is shared and locked across the team.
  # Replace bucket/dynamodb_table with your actual values after creating them.
  backend "s3" {
    bucket         = "grahvani-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "grahvani-terraform-locks"
    encrypt        = true
  }
}

# ─── AWS Provider ─────────────────────────────────────────────────────────────
provider "aws" {
  region = var.aws_region

  # Default tags applied to every resource in this workspace.
  default_tags {
    tags = {
      Project     = "Grahvani"
      Environment = "production"
      ManagedBy   = "terraform"
      Repository  = "grahvani"
    }
  }
}

# ─── Data Sources ─────────────────────────────────────────────────────────────

# Current AWS account identity — used in KMS key policies and IAM resource ARNs.
data "aws_caller_identity" "current" {}

# Current AWS region — used for constructing ARNs without hard-coding the region.
data "aws_region" "current" {}

# ─── Locals ───────────────────────────────────────────────────────────────────
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Common name prefix for all resources
  name_prefix = "grahvani"

  # Common tags merged with resource-specific tags
  common_tags = {
    Project     = "Grahvani"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
