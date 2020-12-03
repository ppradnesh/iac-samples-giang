# variables for resource
variable "resource_group_name" {
  type        = string
  description = "Resource Group Name"
}

variable "region" {
  type        = string
  description = "The region/location"
}

variable "environment_name" {
  type        = string
  description = "Environment Name: dev, test, stage, prod"
  default = "dev"
}

variable "azfw_name" {
  type        = string
  description = "Azure Firewall name"
}

variable "product_name" {
  type        = string
  default = "base"
  description = "PaaS/Product name: aks, apimgmt, appgw, appgw2v2, ase, dbprivate, dbpublic, pciase, sqlinstance"
}

variable "json_file_path_application_rule" {
  type        = string
  default = "application.rule.collections.westus2.json"
  description = "Name of the json file containing application security rules"
}

variable "json_file_path_network_rule" {
  type        = string
  default = "network.rule.collections.westus2.json"
  description = "Name of the json file containing network security rules"
}

variable "json_file_path_nat_rule" {
  type        = string
  default = "network.rule.collections.westus2.json"
  description = "Name of the json file containing nat security rules"
}

variable "source_type_array" {
  type        = map
  description = "Map for subnets in environment"
}
