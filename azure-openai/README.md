# Azure OpenAI Terraform Module

This is a fork of the [Azure OpenAI module](https://github.com/Azure/terraform-azurerm-openai) provided by Azure, updated to support the latest Azure provider versions and deployment configurations.

## Overview

This module creates and manages Azure OpenAI (Cognitive Services) resources including:

- Azure Cognitive Services Account configured for OpenAI
- Model deployments (GPT-3.5, GPT-4, embeddings, etc.)
- Private endpoints for secure connectivity
- Network ACLs and access controls
- Customer-managed encryption keys
- Managed identities

## Breaking Changes from Upstream

This fork includes breaking changes to align with Azure provider updates:

- **Deployment configuration**: The `scale` block has been replaced with `sku` block
  - `scale_type` is now `sku_name` (required field)
  - New SKU values: `Standard`, `DataZoneBatch`, `DataZoneStandard`, `DataZoneProvisionedManaged`, `GlobalBatch`, `GlobalProvisionedManaged`, `GlobalStandard`, `ProvisionedManaged`
- **New parameter**: `dynamic_throttling_enabled` added for both account and deployment levels

## Requirements

| Name      | Version  |
| --------- | -------- |
| terraform | >= 1.3.0 |
| azurerm   | ~> 4.47  |
| random    | >= 3.0   |

## Usage

### Basic Example

```hcl
module "openai" {
  # contiamo-release-please-bump-start
  source = "github.com/contiamo/terraform//azure-openai?ref=v0.8.0"
  # contiamo-release-please-bump-end

  resource_group_name = "my-resource-group"
  location            = "eastus"
  account_name        = "my-openai-account"

  deployment = {
    gpt4 = {
      name          = "gpt-4-deployment"
      model_format  = "OpenAI"
      model_name    = "gpt-4"
      model_version = "0613"
      sku_name      = "Standard"
      capacity      = 10
    }
  }
}
```

### Complete Example with Private Endpoint

```hcl
module "openai" {
# contiamo-release-please-bump-start
  source                         = "github.com/contiamo/terraform//azure-openai?ref=v0.8.0"
# contiamo-release-please-bump-end
  resource_group_name            = "my-resource-group"
  location                       = "eastus"
  account_name                   = "my-openai-account"
  sku_name                       = "S0"
  public_network_access_enabled  = false
  dynamic_throttling_enabled     = true

  identity = {
    type = "SystemAssigned"
  }

  network_acls = [{
    default_action = "Deny"
    ip_rules       = ["203.0.113.0/24"]
    virtual_network_rules = [{
      subnet_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/xxx/subnets/xxx"
    }]
  }]

  deployment = {
    gpt4 = {
      name                       = "gpt-4-deployment"
      model_format               = "OpenAI"
      model_name                 = "gpt-4"
      model_version              = "0613"
      sku_name                   = "Standard"
      capacity                   = 10
      version_upgrade_option     = "OnceNewDefaultVersionAvailable"
      dynamic_throttling_enabled = true
    }

    embeddings = {
      name          = "embeddings-deployment"
      model_format  = "OpenAI"
      model_name    = "text-embedding-ada-002"
      model_version = "2"
      sku_name      = "Standard"
      capacity      = 5
    }
  }

  private_endpoint = {
    pe1 = {
      name                    = "openai-pe"
      vnet_rg_name           = "network-rg"
      vnet_name              = "my-vnet"
      subnet_name            = "private-endpoints-subnet"
      private_dns_entry_enabled = true
    }
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name                               | Description                                                                                                                                                                            | Type                                                                                                                                                                                                                                                                                                                                                                                          | Default       | Required |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | :------: |
| resource_group_name                | Name of the Azure resource group to use. The resource group must exist.                                                                                                                | `string`                                                                                                                                                                                                                                                                                                                                                                                      | n/a           |   yes    |
| location                           | Azure OpenAI deployment region. Set this variable to `null` would use resource group's location.                                                                                       | `string`                                                                                                                                                                                                                                                                                                                                                                                      | n/a           |   yes    |
| account_name                       | Specifies the name of the Cognitive Service Account. Changing this forces a new resource to be created. Leave this variable as default would use a default name with random suffix.    | `string`                                                                                                                                                                                                                                                                                                                                                                                      | `""`          |    no    |
| application_name                   | Name of the application. A corresponding tag would be created on the created resources if `var.default_tags_enabled` is `true`.                                                        | `string`                                                                                                                                                                                                                                                                                                                                                                                      | `""`          |    no    |
| custom_subdomain_name              | The subdomain name used for token-based authentication. Changing this forces a new resource to be created. Leave this variable as default would use a default name with random suffix. | `string`                                                                                                                                                                                                                                                                                                                                                                                      | `null`        |    no    |
| sku_name                           | Specifies the SKU Name for this Cognitive Service Account. Possible values are `F0`, `F1`, `S0`, `S`, `S1`, `S2`, `S3`, `S4`, `S5`, `S6`, `P0`, `P1`, `P2`, `E0` and `DC0`.            | `string`                                                                                                                                                                                                                                                                                                                                                                                      | `"S0"`        |    no    |
| public_network_access_enabled      | Whether public network access is allowed for the Cognitive Account.                                                                                                                    | `bool`                                                                                                                                                                                                                                                                                                                                                                                        | `false`       |    no    |
| local_auth_enabled                 | Whether local authentication methods is enabled for the Cognitive Account.                                                                                                             | `bool`                                                                                                                                                                                                                                                                                                                                                                                        | `true`        |    no    |
| dynamic_throttling_enabled         | Determines whether or not dynamic throttling is enabled. If set to `true`, dynamic throttling will be enabled. If set to `false`, dynamic throttling will not be enabled.              | `bool`                                                                                                                                                                                                                                                                                                                                                                                        | `null`        |    no    |
| outbound_network_access_restricted | Whether outbound network access is restricted for the Cognitive Account.                                                                                                               | `bool`                                                                                                                                                                                                                                                                                                                                                                                        | `false`       |    no    |
| fqdns                              | List of FQDNs allowed for the Cognitive Account.                                                                                                                                       | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                | `null`        |    no    |
| tags                               | A mapping of tags to assign to the resource.                                                                                                                                           | `map(string)`                                                                                                                                                                                                                                                                                                                                                                                 | `{}`          |    no    |
| identity                           | Configuration block for managed identity.                                                                                                                                              | `object({ type = string, identity_ids = optional(list(string)) })`                                                                                                                                                                                                                                                                                                                            | `null`        |    no    |
| customer_managed_key               | Configuration for customer-managed encryption key.                                                                                                                                     | `object({ key_vault_key_id = string, identity_client_id = optional(string) })`                                                                                                                                                                                                                                                                                                                | `null`        |    no    |
| network_acls                       | Network ACL configuration for the Cognitive Account.                                                                                                                                   | `set(object({ default_action = string, ip_rules = optional(set(string)), virtual_network_rules = optional(set(object({ subnet_id = string, ignore_missing_vnet_service_endpoint = optional(bool, false) }))) }))`                                                                                                                                                                             | `null`        |    no    |
| deployment                         | Map of model deployments to create. Each deployment specifies a model to deploy with its configuration.                                                                                | `map(object({ name = string, model_format = string, model_name = string, model_version = string, sku_name = string, rai_policy_name = optional(string), capacity = optional(number), version_upgrade_option = optional(string), dynamic_throttling_enabled = optional(bool) }))`                                                                                                              | `{}`          |    no    |
| private_endpoint                   | Map of private endpoint configurations.                                                                                                                                                | `map(object({ name = string, vnet_rg_name = string, vnet_name = string, subnet_name = string, location = optional(string, null), dns_zone_virtual_network_link_name = optional(string, "dns_zone_link"), private_dns_entry_enabled = optional(bool, false), private_service_connection_name = optional(string, "privateserviceconnection"), is_manual_connection = optional(bool, false) }))` | `{}`          |    no    |
| private_dns_zone                   | Configuration for existing Private DNS Zone to use. Leave as default to create a new Private DNS Zone.                                                                                 | `object({ name = string, resource_group_name = optional(string) })`                                                                                                                                                                                                                                                                                                                           | `null`        |    no    |
| pe_subresource                     | A list of subresource names which the Private Endpoint is able to connect to.                                                                                                          | `list(string)`                                                                                                                                                                                                                                                                                                                                                                                | `["account"]` |    no    |

### Deployment Object Details

The `deployment` variable accepts a map of objects with the following structure:

```hcl
deployment = {
  deployment_key = {
    name                       = string                # (Required) Deployment name
    model_format               = string                # (Required) Model format (e.g., "OpenAI")
    model_name                 = string                # (Required) Model name (e.g., "gpt-4", "gpt-35-turbo")
    model_version              = string                # (Required) Model version (e.g., "0613")
    sku_name                   = string                # (Required) SKU name: Standard, DataZoneBatch, DataZoneStandard,
                                                       #            DataZoneProvisionedManaged, GlobalBatch,
                                                       #            GlobalProvisionedManaged, GlobalStandard, ProvisionedManaged
    capacity                   = number                # (Optional) Tokens-per-Minute in thousands. Defaults to 1 (= 1000 TPM)
    rai_policy_name            = string                # (Optional) RAI policy name
    version_upgrade_option     = string                # (Optional) Version upgrade option: OnceNewDefaultVersionAvailable,
                                                       #            OnceCurrentVersionExpired, NoAutoUpgrade
    dynamic_throttling_enabled = bool                  # (Optional) Enable dynamic throttling
  }
}
```

## Outputs

| Name                 | Description                                                            |
| -------------------- | ---------------------------------------------------------------------- |
| openai_id            | The ID of the Cognitive Service Account                                |
| openai_endpoint      | The endpoint used to connect to the Cognitive Service Account          |
| openai_subdomain     | The subdomain used to connect to the Cognitive Service Account         |
| openai_primary_key   | The primary access key for the Cognitive Service Account (sensitive)   |
| openai_secondary_key | The secondary access key for the Cognitive Service Account (sensitive) |
| private_ip_addresses | A map dictionary of the private IP addresses for each private endpoint |

## Common Model Deployments

### GPT Models

```hcl
deployment = {
  gpt4 = {
    name          = "gpt-4"
    model_format  = "OpenAI"
    model_name    = "gpt-4"
    model_version = "0613"
    sku_name      = "Standard"
    capacity      = 10
  }

  gpt35_turbo = {
    name          = "gpt-35-turbo"
    model_format  = "OpenAI"
    model_name    = "gpt-35-turbo"
    model_version = "0613"
    sku_name      = "Standard"
    capacity      = 30
  }
}
```

### Embeddings

```hcl
deployment = {
  embeddings = {
    name          = "text-embedding-ada-002"
    model_format  = "OpenAI"
    model_name    = "text-embedding-ada-002"
    model_version = "2"
    sku_name      = "Standard"
    capacity      = 10
  }
}
```

## Notes

- Model availability varies by region. Check [Azure OpenAI Service models](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models) for regional availability.
- Capacity is measured in thousands of Tokens-per-Minute (TPM). A capacity of 1 equals 1,000 TPM.
- When using private endpoints, ensure that `public_network_access_enabled` is set to `false`.
- The module supports both system-assigned and user-assigned managed identities.

## License

This module is maintained by Contiamo and is a fork of the original Azure module.
