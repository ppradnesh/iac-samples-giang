# variables.tf

# These should be defined in a new file called environment.tfvars - See README.md
variable "awsAccessKey" {
  description = "The access key granted by AWS."
}

variable "awsSecretKey" {
  description = "The secret key granted by AWS at the time of access key creation."
}

variable "environmentName" {
  description = "A short, lowercase descriptor to use for AWS console item identification. e.g. 'uat' or 'qa'"
}

variable "publicSubnetIpSegment" {
  description = ""
}

variable "privateSubnetIpSegment" {
  description = ""
}

variable "additionalWhitelist" {
description = "Qualys IP addresses"
  type        = list(string)
  default = [
    "0.0.0.0/0",
  ]
}

variable "existingElasticIp" {
  description = "(Optional) An exising, AWS elastic IP that should be used. One will be generated if left blank."
  default     = ""
}

variable "storageVolumeId" {
  description = "Storage volume ID for the persistent database storage across terraform builds"  
}

variable "include_cts" {
  description = "Include the component test service on the application stack deployment"
  type = bool
}

# Other CA certs

variable "caTrustPath" {
  default = "../shared/ssl/ca-trust"
}

# secrets paths

variable "secretsBasePath" {
  default = "../../orchestrator/secrets"
}

variable "createSecretsFilename" {
  default = "create-secrets.sh"
}

variable "serverCertFilename" {
  default = "server.cer"
}

variable "serverKeyFileName" {
  default = "server.key"
}

variable "webclientJsonFileName" {
  default = "webclient.config.json"
}

# cluster definition paths

variable "clusterDefinitionBasePath" {
  default = "../../orchestrator/"
}

variable "releaseBasePath" {
  default = "release/"
}

variable "apiClusterDefinitonFilename" {
  default = "api_stack.yml"
}

variable "dmzClusterDefinitonFilename" {
  default = "dmz_stack.yml"
}

variable "sftpDockerImage" {
  default = "ehr-shared.mib.com/ehr/sftp:0.0.6-bc9f143"
}

# external access

variable "mibIngressCIDRblock" {
  description = "MIB network IP addresses"
  type        = list(string)
  default = [
    "216.5.89.244/32",
    "12.16.75.189/32",
    "12.16.75.176/28",
  ]
}

variable "qualysIngressCIDRblock" {
  description = "Qualys IP addresses"
  type        = list(string)
  default = [
    "64.39.96.0/20",
  ]
}

variable "epicVendorIngressCIDRblock" {
  description = "EPIC Vendor IP Addresses"
  type        = list(string)
  default = [
	// EPIC IPs
    "45.42.34.130/32",
    "68.65.248.130/32",
  ]
}

variable "veradigmVendorIngressCIDRblock" {
  description = "Veradigm Vendor IP Addresses"
  type        = list(string)
  default = [
	// VERADIGM IPs
    "198.181.218.0/24",
    "138.69.222.0/24",
    "216.27.64.0/24",
    "104.166.24.0/24",
  ]
}

variable "healthixVendorIngressCIDRblock" {
  description = "Healthix Vendor IP Addresses"
  type        = list(string)
  default = [
	// Healthix IPs
	"74.201.162.1/32",
	"70.42.47.208/32",
	"74.201.162.80/32",
	"74.201.253.200/32",
	"74.201.253.225/32",
  ]
}

variable "uhinVendorIngressCIDRblock" {
  description = "UHIN Vendor IP Addresses"
  type        = list(string)
  default = [
	  // UHIN IPs
    "199.38.250.0/25",
    "50.227.136.64/27",
    "67.214.225.192/29"
  ]
}

variable "docusignIngressCIDRblock" {
  description = "IPs Docusign traffic originates from when posting to us."
  type        = list(string)
  default = [
    "64.207.216.0/24",
    "64.207.217.0/24",
    "64.207.218.0/24",
    "64.207.219.0/24",
    "162.248.184.0/24",
    "162.248.185.0/24",
    "162.248.186.0/24",
    "162.248.187.0/24",
    "34.212.7.28/32",
    "34.213.201.254/32",
    "34.213.254.17/32",
    "34.215.124.54/32",
    "34.215.142.185/32",
    "34.215.203.190/32",
    "35.164.40.59/32",
    "35.167.67.7/32",
    "52.25.145.215/32",
    "52.27.85.20/32",
    "52.34.155.26/32",
    "52.41.95.219/32",
  ]
}

# these should be more stable below this line

variable "region" {
  default = "us-east-1"
}

variable "availabilityZone" {
  default = "us-east-1a"
}

variable "dmzInstanceType" {
  default = "t3.medium"
}

variable "apiInstanceType" {
  default = "r5ad.large"
}

variable "storageInstanceType" {
  default = "r5ad.large"
}

variable "keyPairName" {
  default = "ehr-shared"
}

variable "privateKeyFilename" {
  default = "ehr-shared.pem"
}

variable "bastionHost" {
  default = "ehr-shared.mib.com"
}

variable "bastionUser" {
  default = "ubuntu"
}

variable "instanceUser" {
  default = "centos"
}

variable "instanceTenancy" {
  default = "default"
}

variable "storageVolumeAttach" {
  default = "/dev/sdf"
}

variable "dnsSupport" {
  default = true
}

variable "dnsHostNames" {
  default = true
}

variable "peerOwnerId" {
  default = "067295851757"
}

variable "sharedVpcId" {
  default = "vpc-05fcffe9bc169aefb"
}

variable "sharedSecurityGroupId" {
  default = "sg-0dafab801bcd18bc6"
}

variable "sharedCidrBlock" {
  default = "172.30.31.0/24"
}

variable "sharedRouteTableId" {
  default = "rtb-036dbff9b6ca79ac8"
}

variable "destinationCIDRblock" {
  default = "0.0.0.0/0"
}

variable "bastionIngressCIDRblock" {
  type    = list(string)
  default = ["172.30.31.123/32"]
}

# end of variables.tf
