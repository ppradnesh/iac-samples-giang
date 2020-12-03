provider "aws" {
    region = "us-east-1"
    version = "~> 2.20"
    profile="QUAL"
}

data "aws_caller_identity" "current" {
}

