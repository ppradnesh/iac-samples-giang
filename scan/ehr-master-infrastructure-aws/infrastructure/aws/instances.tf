/*

This handles the EC2 instances use for the the EHR stack.  In this application,
3 instances are used, arranged into two stacks on two subnets, a DMZ subnet and 
a API subnet.  The three instances areL

 - DMZ instance -> DMZ stack -> DMZ Public Subnet
 - API WEB instance -> API stack -> API Private Subnet
 - API STORAGE instance -> API stack -> API Private Subnet

*/

data "aws_ami" "centos" {
	owners      = ["679593333241"]
	most_recent = true

  filter {
      name   = "name"
      values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
      name   = "architecture"
      values = ["x86_64"]
  }

  filter {
      name   = "root-device-type"
      values = ["ebs"]
  }
}

#DMZ EC2 Instance
resource "aws_instance" "ehr-dmz-01" {
  ami               = data.aws_ami.centos.id
  availability_zone = var.availabilityZone
  instance_type     = var.dmzInstanceType
  key_name          = var.keyPairName
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.ehr-dmz.id
  }
  root_block_device {
    volume_size = 50
    encrypted = true
  }
  volume_tags = {
    Name = "ehr-${var.environmentName}-dmz-vol-01"
  }
  connection {
    type                = "ssh"
    bastion_host        = var.bastionHost
    bastion_user        = var.bastionUser
    bastion_private_key = file(var.privateKeyFilename)
    host                = aws_instance.ehr-dmz-01.private_ip
    user                = var.instanceUser
    private_key         = file(var.privateKeyFilename)
  }
  provisioner "file" {
    source      = "${var.caTrustPath}/"
    destination = "/tmp/ca-trust"    
  }
  provisioner "remote-exec" {
    script = "provision_instance.sh"
  }
  provisioner "file" {
    source      = "squid.conf"
    destination = "/tmp/squid.conf"
  }
  provisioner "file" {
    source      = "${var.secretsBasePath}/${var.environmentName}/${var.serverCertFilename}"
    destination = "/tmp/server.cer"
  }
  provisioner "file" {
    source      = "${var.secretsBasePath}/${var.environmentName}/${var.serverKeyFileName}"
    destination = "/tmp/server.key"
  }
  provisioner "file" {
    source      = "${var.secretsBasePath}/${var.environmentName}/${var.webclientJsonFileName}"
    destination = "/tmp/webclient.config.json"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo sysctl -w net.ipv4.ip_forward=1",
      "echo 'net.ipv4.ip_forward=1' | sudo tee --append /etc/sysctl.conf",
      "sed -i 's|##EHR_SUBDOMAIN##|ehr-${var.environmentName}|' /tmp/squid.conf",
      "sed -i 's|##PRIVATE_SUBNET_CIDR_BLOCK##|${aws_subnet.ehr-private-subnet.cidr_block}|' /tmp/squid.conf",
      "sudo mkdir /etc/squid",
      "sudo mv /tmp/squid.conf /tmp/server.cer /tmp/server.key /etc/squid",
      "sudo iptables -t nat -I PREROUTING 1 -s ${aws_subnet.ehr-private-subnet.cidr_block} -p tcp --dport 80 -j REDIRECT --to-port 3128",
      "sudo iptables -t nat -I PREROUTING 1 -s ${aws_subnet.ehr-private-subnet.cidr_block} -p tcp --dport 443 -j REDIRECT --to-port 3129",
      "sudo iptables -t nat -I PREROUTING 1 -s ${aws_subnet.ehr-private-subnet.cidr_block} -p tcp --dport 9443 -j REDIRECT --to-port 3129",
      "sudo iptables -t nat -I PREROUTING 1 -s ${aws_subnet.ehr-private-subnet.cidr_block} -p tcp --dport 14430 -j REDIRECT --to-port 3129",
      "sudo mkdir -p /var/spool/squid && sudo chmod -R 775 /var/spool/squid",
      "sudo mkdir -p /var/log/squid && sudo chmod -R 775 /var/log/squid",
      "sudo yum install -y squid",
      "sudo squid -N -f /etc/squid/squid.conf -z",
      "sudo squid",
      "sudo systemctl enable squid",
    ]
  }
  depends_on = [aws_route.ehr-shared-route]
  tags = {
    Name = "ehr-${var.environmentName}-dmz-01"
    Environment = "${var.environmentName}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dmz-cpu-check" {
  alarm_name                = "ehr-${var.environmentName}-dmz-cpu-check"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "3600"
  statistic                 = "Average"
  threshold                 = "95"
  alarm_description         = "This metric monitors the CPU utilization"
  alarm_actions             = [ "arn:aws:sns:us-east-1:067295851757:EHRDevTeam" ]
  dimensions                = {
    InstanceId = "${aws_instance.ehr-dmz-01.id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "dmz-status-check" {
  alarm_name                = "ehr-${var.environmentName}-dmz-status-check"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "StatusCheckFailed"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Maximum"
  threshold                 = "1.0"
  alarm_description         = "This metric monitors the EC2 Status Checks"
  alarm_actions             = [ "arn:aws:sns:us-east-1:067295851757:EHRDevTeam" ]
  dimensions                = {
    InstanceId = "${aws_instance.ehr-dmz-01.id}"
  }
}

#API WEB EC2 Instance
resource "aws_instance" "ehr-api-01" {
  ami               = data.aws_ami.centos.id
  availability_zone = var.availabilityZone
  instance_type     = var.apiInstanceType
  key_name          = var.keyPairName
  vpc_security_group_ids = [
    aws_security_group.ehr-security-group-bastion.id,
    aws_security_group.ehr-security-group-cluster.id,
    aws_security_group.ehr-security-group-api.id,
  ]
  subnet_id         = aws_subnet.ehr-private-subnet.id
  source_dest_check = false
  root_block_device {
    volume_size = 50
    encrypted = true
  }
  volume_tags = {
    Name = "ehr-${var.environmentName}-api-vol-01"
  }
  connection {
    type                = "ssh"
    bastion_host        = var.bastionHost
    bastion_user        = var.bastionUser
    bastion_private_key = file(var.privateKeyFilename)
    host                = aws_instance.ehr-api-01.private_ip
    user                = var.instanceUser
    private_key         = file(var.privateKeyFilename)
  }
  provisioner "file" {
    source      = "${var.caTrustPath}/"
    destination = "/tmp/ca-trust"    
  }
  provisioner "remote-exec" {
    script = "provision_instance.sh"
  }
  depends_on = [
    aws_route.ehr-shared-route,
    aws_instance.ehr-dmz-01,
    aws_security_group.ehr-security-group-dmz-api,
  ]
  tags = {
    Name = "ehr-${var.environmentName}-api-01"
    Environment = "${var.environmentName}"
  }
}

resource "aws_cloudwatch_metric_alarm" "api-cpu-check" {
  alarm_name                = "ehr-${var.environmentName}-api-cpu-check"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "3600"
  statistic                 = "Average"
  threshold                 = "95"
  alarm_description         = "This metric monitors the CPU utilization"
  alarm_actions             = [ "arn:aws:sns:us-east-1:067295851757:EHRDevTeam" ]
  dimensions                = {
    InstanceId = "${aws_instance.ehr-api-01.id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "api-status-check" {
  alarm_name                = "ehr-${var.environmentName}-api-status-check"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "StatusCheckFailed"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Maximum"
  threshold                 = "1.0"
  alarm_description         = "This metric monitors the EC2 Status Checks"
  alarm_actions             = [ "arn:aws:sns:us-east-1:067295851757:EHRDevTeam" ]
  dimensions                = {
    InstanceId = "${aws_instance.ehr-api-01.id}"
  }
}

#API STORAGE EC2 Instance
resource "aws_instance" "ehr-storage-01" {
  ami               = data.aws_ami.centos.id
  availability_zone = var.availabilityZone
  instance_type     = var.storageInstanceType
  key_name          = var.keyPairName
  vpc_security_group_ids = [
    aws_security_group.ehr-security-group-bastion.id,
    aws_security_group.ehr-security-group-cluster.id,
  ]
  subnet_id         = aws_subnet.ehr-private-subnet.id
  source_dest_check = false
  root_block_device {
    volume_size = 50
    encrypted = true
  }
  volume_tags = {
    Name = "ehr-${var.environmentName}-storage-vol-01"
  }
  connection {
    type                = "ssh"
    bastion_host        = var.bastionHost
    bastion_user        = var.bastionUser
    bastion_private_key = file(var.privateKeyFilename)
    host                = aws_instance.ehr-storage-01.private_ip
    user                = var.instanceUser
    private_key         = file(var.privateKeyFilename)
  }
  provisioner "file" {
    source      = "${var.caTrustPath}/"
    destination = "/tmp/ca-trust"    
  }
  provisioner "remote-exec" {
    script = "provision_instance.sh"
  }
  depends_on = [
    aws_route.ehr-shared-route,
    aws_instance.ehr-dmz-01,
    aws_security_group.ehr-security-group-dmz-api,
  ]
  tags = {
    Name = "ehr-${var.environmentName}-storage-01"
    Environment = "${var.environmentName}"
  }
}

resource "aws_volume_attachment" "storage_volume_att" {
  device_name = var.storageVolumeAttach
  volume_id   = var.storageVolumeId
  instance_id = aws_instance.ehr-storage-01.id
}

resource "aws_cloudwatch_metric_alarm" "storage-cpu-check" {
  alarm_name                = "ehr-${var.environmentName}-storage-cpu-check"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "3600"
  statistic                 = "Average"
  threshold                 = "95"
  alarm_description         = "This metric monitors the CPU utilization"
  alarm_actions             = [ "arn:aws:sns:us-east-1:067295851757:EHRDevTeam" ]
  dimensions                = {
    InstanceId = "${aws_instance.ehr-storage-01.id}"
  }
}

resource "aws_cloudwatch_metric_alarm" "storage-status-check" {
  alarm_name                = "ehr-${var.environmentName}-storage-status-check"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "StatusCheckFailed"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Maximum"
  threshold                 = "1.0"
  alarm_description         = "This metric monitors the EC2 Status Checks"
  alarm_actions             = [ "arn:aws:sns:us-east-1:067295851757:EHRDevTeam" ]
  dimensions                = {
    InstanceId = "${aws_instance.ehr-storage-01.id}"
  }
}
