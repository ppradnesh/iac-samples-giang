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
}

variable "azfw_name" {
  type        = string
  description = "Azure Firewall name"
}
