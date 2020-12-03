## AzFW Application Rule Collection ##

locals {
    raw_json_file        = fileexists("../environments/${var.environment_name}/${var.product_name}/${var.json_file_path_application_rule}") ? jsondecode(file("../environments/${var.environment_name}/${var.product_name}/${var.json_file_path_application_rule}")) : null 
    operation_list       = local.raw_json_file == null ? [] : flatten([
      for rule_collection in local.raw_json_file.application_rule_collections : {
        name             = rule_collection.name
        priority         = rule_collection.priority
        action           = rule_collection.action
        rules            = rule_collection.rules
      }
    ])
}

resource "azurerm_firewall_application_rule_collection" "application_rule_collection" {
  for_each            = {for rule_collection in local.operation_list : "${rule_collection.name}" => rule_collection}

  name                = each.value.name
  azure_firewall_name = var.azfw_name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = each.value.action

  
  dynamic "rule" {
    for_each = each.value.rules
    content {
      name             = rule.value.name
      source_addresses = length(rule.value.source_addresses) == 0 ? "${lookup(var.source_type_array, rule.value.source_type, ["4.4.4.4"])}" : rule.value.source_addresses
      target_fqdns     = rule.value.target_fqdns
      dynamic "protocol" {
        for_each = rule.value.protocol
        content {
          port = lookup(protocol.value, "port", "null") == "null" ? null : protocol.value.port
          type = protocol.value.type
        }
        
      }
    }
  }
}