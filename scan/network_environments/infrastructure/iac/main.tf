resource "aws_vpc" "my_vpc" {
  cidr_block = var.network_config.vpc_cidr
  tags = {
    Name = var.network_config.vpc_name
    NameTag2 = var.network_config.vpc_name
    ApplicationTag = var.network_config.vpc_name
    NetworkTag = "MGMT2"
    NameTag = var.network_config.vpc_name
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = var.network_config.subnet_cidr
  availability_zone = "us-west-2a"
  tags = {
    SubnetName = var.network_config.subnet_name
  }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-tf-log-bucket"
  acl = "log-delivery-write"
}
