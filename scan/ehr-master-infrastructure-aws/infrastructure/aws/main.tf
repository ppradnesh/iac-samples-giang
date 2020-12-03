# main.tf

# register aws as the provider
#    note: requires the creation of awsAccessKey and awsSecretKey variables. See /README.md for details.
provider "aws" {
#  access_key = var.awsAccessKey
# secret_key = var.awsSecretKey
  region     = "us-east-1"
# region     = var.region
}

