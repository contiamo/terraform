data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "azurerm_cognitive_account" "this" {
  kind                               = "OpenAI"
  location                           = var.location
  name                               = var.account_name
  resource_group_name                = data.azurerm_resource_group.this.name
  sku_name                           = var.sku_name
  custom_subdomain_name              = var.custom_subdomain_name
  dynamic_throttling_enabled         = var.dynamic_throttling_enabled
  fqdns                              = var.fqdns
  local_auth_enabled                 = var.local_auth_enabled
  outbound_network_access_restricted = var.outbound_network_access_restricted
  public_network_access_enabled      = var.public_network_access_enabled
  tags                               = var.tags

  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []
    content {
      key_vault_key_id   = customer_managed_key.value.key_vault_key_id
      identity_client_id = customer_managed_key.value.identity_client_id
    }
  }
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  dynamic "network_acls" {
    for_each = var.network_acls != null ? var.network_acls : []
    content {
      default_action = network_acls.value.default_action
      ip_rules       = network_acls.value.ip_rules

      dynamic "virtual_network_rules" {
        for_each = network_acls.value.virtual_network_rules != null ? network_acls.value.virtual_network_rules : []
        content {
          subnet_id                            = virtual_network_rules.value.subnet_id
          ignore_missing_vnet_service_endpoint = virtual_network_rules.value.ignore_missing_vnet_service_endpoint
        }
      }
    }
  }
}

resource "azurerm_cognitive_deployment" "this" {
  for_each = var.deployment

  cognitive_account_id       = azurerm_cognitive_account.this.id
  name                       = each.value.name
  rai_policy_name            = each.value.rai_policy_name
  version_upgrade_option     = each.value.version_upgrade_option
  dynamic_throttling_enabled = each.value.dynamic_throttling_enabled

  model {
    format  = each.value.model_format
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = try(each.value.capacity, 1)
  }
}
