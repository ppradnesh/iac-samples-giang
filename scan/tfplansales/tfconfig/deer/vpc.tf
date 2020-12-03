data "aws_vpc" "isg_vpn" {
  tags = {
    Name = local.vpc_name_tag
  }
}

data "aws_subnet_ids" "vpn_subnets" {
  vpc_id = data.aws_vpc.isg_vpn.id

  tags = {
    Name = "*PrivateSubnet*"
  }
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = data.aws_vpc.isg_vpn.id

  tags = {
    Name = "*PublicSubnet*"
  }
}
