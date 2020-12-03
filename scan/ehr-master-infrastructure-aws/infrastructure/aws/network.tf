# network.tf
# Create: VPC/Subnets/Security Groups/Route Tables

# create the VPC
resource "aws_vpc" "ehr-vpc" {
  cidr_block           = "172.30.${var.publicSubnetIpSegment}.0/23"
  instance_tenancy     = var.instanceTenancy
  enable_dns_support   = var.dnsSupport
  enable_dns_hostnames = var.dnsHostNames
  tags = {
    Name = "ehr-${var.environmentName}"
    Environment = "${var.environmentName}"
  }
}

# create vpc peering connection to ehr-shared
resource "aws_vpc_peering_connection" "ehr-shared" {
  peer_owner_id = var.peerOwnerId
  vpc_id        = var.sharedVpcId
  peer_vpc_id   = aws_vpc.ehr-vpc.id
  auto_accept   = true
  tags = {
    Name = "ehr-shared-${var.environmentName}"
    Environment = "${var.environmentName}"
  }
}

# create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "ehr-internet-gateway" {
  vpc_id = aws_vpc.ehr-vpc.id
  tags = {
    Name = "ehr-${var.environmentName}"
    Environment = "${var.environmentName}"
  }
}

# create the public subnet
resource "aws_subnet" "ehr-public-subnet" {
  vpc_id                  = aws_vpc.ehr-vpc.id
  cidr_block              = "172.30.${var.publicSubnetIpSegment}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availabilityZone
  tags = {
    Name = "ehr-${var.environmentName}-public"
    Environment = "${var.environmentName}"
  }
}

# create the private subnet
resource "aws_subnet" "ehr-private-subnet" {
  vpc_id            = aws_vpc.ehr-vpc.id
  cidr_block        = "172.30.${var.privateSubnetIpSegment}.0/24"
  availability_zone = var.availabilityZone
  tags = {
    Name = "ehr-${var.environmentName}-private"
    Environment = "${var.environmentName}"
  }
}

# Create the route table for use by instances in the public/dmz subnet
resource "aws_route_table" "ehr-public-route-table" {
  vpc_id = aws_vpc.ehr-vpc.id
  route {
    cidr_block                = var.sharedCidrBlock
    vpc_peering_connection_id = aws_vpc_peering_connection.ehr-shared.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ehr-internet-gateway.id
  }
  tags = {
    Name = "ehr-${var.environmentName}-public-route-table"
    Environment = "${var.environmentName}"
  }
}

resource "aws_route_table_association" "ehr-public-route-table-association" {
  subnet_id      = aws_subnet.ehr-public-subnet.id
  route_table_id = aws_route_table.ehr-public-route-table.id
}

# create a network interface to use for the dmz instance. we need it in advance to
#     set the route table outbound access for the internal subnet through the forward proxy
resource "aws_network_interface" "ehr-dmz" {
  subnet_id         = aws_subnet.ehr-public-subnet.id
  source_dest_check = false
  security_groups = [
    aws_security_group.ehr-security-group-bastion.id,
    aws_security_group.ehr-security-group-public-web-server.id,
    aws_security_group.ehr-security-group-dmz-api.id,
    aws_security_group.ehr-security-group-vendor.id,
    aws_security_group.ehr-security-group-docusign.id,
  ]
  tags = {
    Name = "ehr-${var.environmentName}-dmz"
    Environment = "${var.environmentName}"
  }
}

resource "aws_route_table" "ehr-private-route-table" {
  vpc_id = aws_vpc.ehr-vpc.id
  tags = {
    Name = "ehr-${var.environmentName}-private-route-table"
    Environment = "${var.environmentName}"
  }
}

resource "aws_route" "ehr-private-route-shared-peering" {
  route_table_id            = aws_route_table.ehr-private-route-table.id
  destination_cidr_block    = var.sharedCidrBlock
  vpc_peering_connection_id = aws_vpc_peering_connection.ehr-shared.id
}

resource "aws_route" "ehr-private-route-network-interface" {
  route_table_id         = aws_route_table.ehr-private-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.ehr-dmz.id
}

resource "aws_route_table_association" "ehr-private-route-table-association" {
  subnet_id      = aws_subnet.ehr-private-subnet.id
  route_table_id = aws_route_table.ehr-private-route-table.id
}

resource "aws_route" "ehr-shared-route" {
  route_table_id            = var.sharedRouteTableId
  destination_cidr_block    = aws_vpc.ehr-vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.ehr-shared.id
  depends_on = [
    aws_route_table.ehr-public-route-table,
    aws_route_table.ehr-private-route-table,
  ]
}

# create the bastion security group
resource "aws_security_group" "ehr-security-group-bastion" {
  vpc_id      = aws_vpc.ehr-vpc.id
  name        = "ehr-${var.environmentName}-bastion"
  description = "ehr-bastion"
  ingress {
    cidr_blocks = var.bastionIngressCIDRblock
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = var.bastionIngressCIDRblock
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  tags = {
    Name = "ehr-${var.environmentName}-bastion"
    Environment = "${var.environmentName}"
  }
}

# create the cluster security group
resource "aws_security_group" "ehr-security-group-cluster" {
  vpc_id      = aws_vpc.ehr-vpc.id
  name        = "ehr-${var.environmentName}-cluster"
  description = "ehr-cluster"
  ingress {
    cidr_blocks = [aws_subnet.ehr-private-subnet.cidr_block]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = {
    Name = "ehr-${var.environmentName}-cluster"
    Environment = "${var.environmentName}"
  }
}

# create the dmz security group
resource "aws_security_group" "ehr-security-group-dmz-api" {
  vpc_id      = aws_vpc.ehr-vpc.id
  name        = "ehr-${var.environmentName}-dmz"
  description = "ehr-dmz"
  ingress {
    cidr_blocks = [aws_subnet.ehr-private-subnet.cidr_block]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = [aws_subnet.ehr-private-subnet.cidr_block]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = [aws_subnet.ehr-private-subnet.cidr_block]
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = [aws_subnet.ehr-private-subnet.cidr_block]
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = [aws_subnet.ehr-private-subnet.cidr_block]
    from_port   = 14430
    to_port     = 14430
    protocol    = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = {
    Name = "ehr-${var.environmentName}-dmz-api"
    Environment = "${var.environmentName}"
  }
}

# create the api security group
resource "aws_security_group" "ehr-security-group-api" {
  vpc_id      = aws_vpc.ehr-vpc.id
  name        = "ehr-${var.environmentName}-api"
  description = "ehr-api"
  ingress {
    cidr_blocks = [aws_subnet.ehr-public-subnet.cidr_block]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = {
    Name = "ehr-${var.environmentName}-api"
    Environment = "${var.environmentName}"
  }
}

# create the public web server security group
resource "aws_security_group" "ehr-security-group-public-web-server" {
  vpc_id      = aws_vpc.ehr-vpc.id
  name        = "ehr-${var.environmentName}-public-web-server"
  description = "ehr-public-web-server"
  ingress {
    description = "MIB Network Access"
    cidr_blocks = var.mibIngressCIDRblock
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  ingress {
    description = "MIB Network Access"
    cidr_blocks = var.mibIngressCIDRblock
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  ingress {
    description = "Qualys Network Access"
    cidr_blocks = var.qualysIngressCIDRblock
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  ingress {
    description = "Qualys Network Access"
    cidr_blocks = var.qualysIngressCIDRblock
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = var.additionalWhitelist
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = var.additionalWhitelist
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = {
    Name = "ehr-${var.environmentName}-public-web-server"
    Environment = "${var.environmentName}"
  }
}

# create the vendor security group
resource "aws_security_group" "ehr-security-group-vendor" {
  vpc_id      = aws_vpc.ehr-vpc.id
  name        = "ehr-${var.environmentName}-vendor"
  description = "ehr-vendor"
  ingress {
    description = "EPIC Network Access"
    cidr_blocks = var.epicVendorIngressCIDRblock
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  ingress {
    description = "Veradigm Network Access"
    cidr_blocks = var.veradigmVendorIngressCIDRblock
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  ingress {
    description = "Healthix Network Access"
    cidr_blocks = var.healthixVendorIngressCIDRblock
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  ingress {
    description = "UHIN Network Access"
    cidr_blocks = var.uhinVendorIngressCIDRblock
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  ingress {
    description = "EPIC Network Access"
    cidr_blocks = var.epicVendorIngressCIDRblock
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
  }
  ingress {
    description = "Veradigm Network Access"
    cidr_blocks = var.veradigmVendorIngressCIDRblock
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
  }
  ingress {
    description = "Healthix Network Access"
    cidr_blocks = var.healthixVendorIngressCIDRblock
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
  }
  ingress {
    description = "UHIN Network Access"
    cidr_blocks = var.uhinVendorIngressCIDRblock
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
  }
  ingress {
    description = "MIB Network Access"
    cidr_blocks = var.mibIngressCIDRblock
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
  }
  ingress {
    description = "Qualys Network Access"
    cidr_blocks = var.qualysIngressCIDRblock
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = {
    Name = "ehr-${var.environmentName}-vendor"
    Environment = "${var.environmentName}"
  }
}

# create the docusign security group
resource "aws_security_group" "ehr-security-group-docusign" {
  vpc_id      = aws_vpc.ehr-vpc.id
  name        = "ehr-${var.environmentName}-docusign"
  description = "ehr-docusign"
  ingress {
    description = "Docusign Network Access"
    cidr_blocks = var.docusignIngressCIDRblock
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
  tags = {
    Name = "ehr-${var.environmentName}-docusign"
    Environment = "${var.environmentName}"
  }
}

# These are an a/b path depending on whether an existing elastic ip was supplied

resource "aws_eip" "ehr-dmz" {
  count      = var.existingElasticIp == "" ? 1 : 0
  vpc        = true
  instance   = aws_instance.ehr-dmz-01.id
  depends_on = [aws_internet_gateway.ehr-internet-gateway]
  tags = {
    Name = "ehr-${var.environmentName}-dmz-cluster"
    Environment = "${var.environmentName}"
  }
}

data "aws_eip" "existing-ehr-dmz" {
  count     = var.existingElasticIp == "" ? 0 : 1
  public_ip = ""
}

resource "aws_eip_association" "ehr-dmz" {
  count       = var.existingElasticIp == "" ? 0 : 1
  public_ip   = ""
  instance_id = aws_instance.ehr-dmz-01.id
}

resource "aws_security_group_rule" "ehr-shared-ingress-dmz-existing" {
  count             = var.existingElasticIp == "" ? 0 : 1
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${data.aws_eip.existing-ehr-dmz[0].public_ip}/32"]
  security_group_id = var.sharedSecurityGroupId
  description       = "ehr-${var.environmentName}-dmz"
}

resource "aws_security_group_rule" "ehr-shared-ingress-dmz" {
  count             = var.existingElasticIp == "" ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${aws_eip.ehr-dmz[0].public_ip}/32"]
  security_group_id = var.sharedSecurityGroupId
  description       = "ehr-${var.environmentName}-dmz"
}

# end elastic ip a/b

resource "aws_route53_zone" "ehr" {
  name = "ehr-${var.environmentName}"
  vpc {
    vpc_id = aws_vpc.ehr-vpc.id
  }
  vpc {
    vpc_id = var.sharedVpcId
  }
}

resource "aws_route53_record" "storage" {
  zone_id = aws_route53_zone.ehr.id
  name    = "storage-01"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ehr-storage-01.private_ip]
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.ehr.id
  name    = "api-01"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ehr-api-01.private_ip]
}

resource "aws_route53_record" "dmz" {
  zone_id = aws_route53_zone.ehr.id
  name    = "dmz-01"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ehr-dmz-01.private_ip]
}

