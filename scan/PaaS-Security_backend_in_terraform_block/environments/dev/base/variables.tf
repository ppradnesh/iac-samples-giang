# variables for resource

variable "product_name" {
  type        = string
  description = "PaaS/Product name: aks, api_mgmt, app_gw, app_gw2v2, ase, databricks_public, databricks_private, pciase, sqlinstance"
}

variable "json_file_path_application_rule" {
  type        = string
  description = "Name of the json file containing application security rules"
}

variable "json_file_path_network_rule" {
  type        = string
  description = "Name of the json file containing network security rules"
}

variable "json_file_path_nat_rule" {
  type        = string
  description = "Name of the json file containing nat security rules"
}
