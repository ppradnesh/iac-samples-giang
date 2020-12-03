terraform {
  required_version = ">=0.12.19"
  backend "consul" {
    address = "demo.consul.io"
    scheme  = "https"
    path    = "example_app/terraform_state"
  }
}

# Configure the Azure Provider
  provider "azurerm" {
    version         = "1.41.0"
  }