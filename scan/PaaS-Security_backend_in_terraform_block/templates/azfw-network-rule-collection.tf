## AzFW Network Rule Collection ##

locals {
    raw_json_file_nrc        = fileexists("../environments/${var.environment_name}/${var.product_name}/${var.json_file_path_network_rule}") ? jsondecode(file("../environments/${var.environment_name}/${var.product_name}/${var.json_file_path_network_rule}")) : null 
    operation_list_nrc       = local.raw_json_file_nrc == null ? [] : flatten([
      for rule_collection in local.raw_json_file_nrc.network_rule_collections : {
        name             = rule_collection.name
        priority         = rule_collection.priority
        action           = rule_collection.action
        rules            = rule_collection.rules
      }
    ])
}

resource "azurerm_firewall_network_rule_collection" "network_rule_collection" {
  for_each            = {for rule_collection in local.operation_list_nrc : "${rule_collection.name}" => rule_collection}

  name                = each.value.name
  azure_firewall_name = var.azfw_name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = each.value.action
  
  dynamic "rule" {
    for_each = each.value.rules
    content {
      name                      = tostring(rule.value.name)
      source_addresses          = length(rule.value.source_addresses) == 0 ? "${lookup(var.source_type_array, rule.value.source_type, ["4.4.4.4"])}" : rule.value.source_addresses
      destination_addresses     = rule.value.destination_addresses
      protocols                 = rule.value.protocols
      destination_ports         = rule.value.destination_ports
    }
  }
}