## AzFW NAT Rule Collection ##

locals {
    raw_json_file_nat        = fileexists("../environments/${var.environment_name}/${var.product_name}/${var.json_file_path_nat_rule}") ? jsondecode(file("../environments/${var.environment_name}/${var.product_name}/${var.json_file_path_nat_rule}")) : null 
    operation_list_nat       = local.raw_json_file_nat == null ? [] : flatten([
      for rule_collection in local.raw_json_file_nat.nat_rule_collections : {
        name             = rule_collection.name
        priority         = rule_collection.priority
        action           = rule_collection.action
        rules            = rule_collection.rules
      }
    ])
}

resource "azurerm_firewall_nat_rule_collection" "nat_rule_collection" {
  for_each            = {for rule_collection in local.operation_list_nat : "${rule_collection.name}" => rule_collection}

  name                = each.value.name
  azure_firewall_name = var.azfw_name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = each.value.action
  
  dynamic "rule" {
    for_each = each.value.rules
    content {
      name                       = tostring(rule.value.name)
      source_addresses           = rule.value.source_addresses
      destination_addresses      = rule.value.destination_addresses
      destination_ports          = rule.value.destination_ports
      protocols                  = rule.value.protocols
      translated_address         = rule.value.translated_address
      translated_port            = rule.value.translated_port
    }
  }
}