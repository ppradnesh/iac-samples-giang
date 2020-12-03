resource_group_name                     = "paas-vnet-dev-rg"
region                                  = "westus2"
environment_name                        = "dev"
azfw_name                               = "az-paas-dev-westus2-fw"
source_type_array  = {
        "databricks_public"   = ["10.155.131.0/26"],
        "databricks_private"  = ["10.155.131.64/26"],
        "sqldb_mi"            = ["10.155.134.0/26"],
        "app_gw"              = ["10.155.132.0/26"],
        "app_gw2v2"           = ["10.155.132.64/26"],
        "api_mgmt"            = ["10.155.133.0/26"],
        "ase"                 = ["10.155.129.0/24"],
        "pciase"              = ["10.155.130.0/24"],
        "aks"                 = ["10.155.156.0/22"]
}