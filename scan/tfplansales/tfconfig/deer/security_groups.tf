data "aws_security_group" "deere_internal_http" {
  filter {
    name = "group-name"
    values = [
      "deere-global-security-groups-${data.aws_vpc.isg_vpn.id}-DeereNetworkHTTP-*"]
  }
}

data "aws_security_group" "deere_internal_https" {
  filter {
    name = "group-name"
    values = [
      "deere-global-security-groups-${data.aws_vpc.isg_vpn.id}-DeereNetworkHTTPS-*"]
  }
}

data "aws_security_group" "deere_open_http" {
  filter {
    name = "group-name"
    values = [
      "deere-global-security-groups-${data.aws_vpc.isg_vpn.id}-DeereOpenHTTP-*"]
  }
}

data "aws_security_group" "deere_open_https" {
  filter {
    name = "group-name"
    values = [
      "deere-global-security-groups-${data.aws_vpc.isg_vpn.id}-DeereOpenHTTPS-*"]
  }
}

resource "aws_security_group" "private_security_group" {
  vpc_id = data.aws_vpc.isg_vpn.id
  description = "A security group to allow any traffic from the public security group (load balancers) to the services"
  tags = local.default_tags
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = [
      data.aws_security_group.deere_open_https.id,
      data.aws_security_group.deere_open_http.id
    ]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
