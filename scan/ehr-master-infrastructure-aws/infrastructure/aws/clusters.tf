/*

This handles the actual deployment of the docker stacks to each of the
relevant boxes to get the full EHR docker stacks up and running.  It 
accomplishes 3 main tasks:
 - Copy relevant secret files up to the necessary boxes
 - Create the needed docker secrets
 - Initialize and join the docker swarms
 - Run a "docker stack deploy" on the swarms

*/

#DMZ cluster
resource "null_resource" "deploy_dmz_cluster" {
  triggers = {
    dmz_instance_id = "${aws_instance.ehr-dmz-01.id}"
    timestamp       = timestamp()
  }
  connection {
    host                = aws_instance.ehr-dmz-01.private_ip
    type                = "ssh"
    bastion_host        = var.bastionHost
    bastion_user        = var.bastionUser
    bastion_private_key = file(var.privateKeyFilename)
    user                = var.instanceUser
    private_key         = file(var.privateKeyFilename)
  }
  provisioner "remote-exec" {
    inline = [
      "sudo docker swarm init",
      "sudo docker secret rm api_private_ip",
      "echo '${aws_route53_record.api.name}.${aws_route53_zone.ehr.name}' | sudo docker secret create api_private_ip -",
      "sudo docker rm -f ehr-sftp",
      "sudo docker run --name ehr-sftp --publish 2222:22 -v /var/lib/docker/volumes/sftp:/home/sftp --restart always --detach ${var.sftpDockerImage}",
    ]
  }
}

# API cluster
resource "null_resource" "deploy_api_cluster_01" {
  triggers = {
    api_instance_id = "${aws_instance.ehr-api-01.id}"
    timestamp       = timestamp()
  }
  connection {
    host                = aws_instance.ehr-api-01.private_ip
    type                = "ssh"
    bastion_host        = var.bastionHost
    bastion_user        = var.bastionUser
    bastion_private_key = file(var.privateKeyFilename)
    user                = var.instanceUser
    private_key         = file(var.privateKeyFilename)
  }
  provisioner "remote-exec" {
    inline = [
      "sudo service docker restart",
      "sudo docker swarm leave --force",
      "sudo docker swarm init",
      "sudo docker swarm update --dispatcher-heartbeat 60s --task-history-limit 50",
      "sudo docker node update --label-add type=web $(sudo docker node ls --filter name=$(hostname) -q)",
      "yes | sudo docker network rm ingress && sleep 10s && sudo docker network create --driver overlay --ingress --subnet=10.255.0.0/16 --gateway=10.255.0.1 ingress",
    ]
  }
  depends_on = [null_resource.deploy_dmz_cluster]
}

resource "null_resource" "deploy_api_cluster_02" {
  triggers = {
    storage_instance_id = "${aws_instance.ehr-storage-01.id}"
    api_cluster_01_id = "${null_resource.deploy_api_cluster_01.id}"
  }
  connection {
    host                = aws_instance.ehr-storage-01.private_ip
    type                = "ssh"
    bastion_host        = var.bastionHost
    bastion_user        = var.bastionUser
    bastion_private_key = file(var.privateKeyFilename)
    user                = var.instanceUser
    private_key         = file(var.privateKeyFilename)
  }
  provisioner "file" {
    source      = var.privateKeyFilename
    destination = "/tmp/${var.privateKeyFilename}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /var/ehr",
      "sudo mount /dev/nvme2n1 /var/ehr", 
      "sudo echo \"UUID=$(sudo /sbin/blkid -ovalue -sUUID /dev/nvme2n1) /var/ehr xfs defaults 0 0\" | sudo tee -a /etc/fstab",
      "sudo mkdir -p /var/ehr/applicantsearchservice_db /var/ehr/epicvendorservice_db /var/ehr/documentsigningservice_db /var/ehr/documentstorageservice_db /var/ehr/veradigmvendorservice_db /var/ehr/userservice_db /var/ehr/healthixvendorservice_db /var/ehr/rgavendorservice_db /var/ehr/analyticservice_db /var/ehr/veriskvendorservice_db /var/ehr/mhcvendorservice_db /var/ehr/uhinvendorservice_db /var/ehr/auditservice_db /var/ehr/messagebroker /var/ehr/elasticsearch /var/ehr/elasticsearch1",
      "sudo chown -R centos /var/ehr/elasticsearch",
      "sudo chown -R centos /var/ehr/elasticsearch1",
      "chmod 600 /tmp/${var.privateKeyFilename}",
      "ssh -o StrictHostKeyChecking=no -i /tmp/${var.privateKeyFilename} ${var.instanceUser}@${aws_instance.ehr-api-01.private_ip} 'sudo docker swarm join-token --quiet worker' | tee /tmp/token",
      "sudo docker swarm leave --force",
      "sudo docker swarm join --token $(cat /tmp/token) ${aws_instance.ehr-api-01.private_ip}:2377",
      "sudo rm -rf /tmp/${var.privateKeyFilename} /tmp/token",
    ]
  }
  depends_on = [
  	null_resource.deploy_api_cluster_01,
  	aws_volume_attachment.storage_volume_att
  ]
}

resource "null_resource" "deploy_api_cluster_03_no_cts" {
  count = var.include_cts ? 0 : 1

  triggers = {
    api_instance_id = "${aws_instance.ehr-api-01.id}"
    storage_instance_id = "${aws_instance.ehr-storage-01.id}"
    api_cluster_02_id = "${null_resource.deploy_api_cluster_02.id}"
  }
  provisioner "local-exec" {
    command = "cd ${path.module}/release && sh ./deploy.sh -e ${var.environmentName} -r 1.27.0 -u"
  }
  depends_on = [null_resource.deploy_api_cluster_02]
}

resource "null_resource" "deploy_api_cluster_03_with_cts" {
  count = var.include_cts ? 1 : 0

  triggers = {
    api_instance_id = "${aws_instance.ehr-api-01.id}"
    storage_instance_id = "${aws_instance.ehr-storage-01.id}"
    api_cluster_02_id = "${null_resource.deploy_api_cluster_02.id}"
  }
  provisioner "local-exec" {
    command = "cd ${path.module}/release && sh ./deploy.sh -e ${var.environmentName} -r 1.27.0 -c -u"
  }
  depends_on = [null_resource.deploy_api_cluster_02]
}

