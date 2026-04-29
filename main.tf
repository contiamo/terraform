# Lookup vault only if vault_id not provided AND we need to fetch the item
data "onepassword_vault" "vault" {
  count = var.item == null && var.vault_id == null ? 1 : 0
  name  = var.vault_name
}

locals {
  # Use provided vault_id, or look it up
  vault_uuid = var.vault_id != null ? var.vault_id : (
    length(data.onepassword_vault.vault) > 0 ? data.onepassword_vault.vault[0].uuid : null
  )
}

# Lookup item only if item not provided
data "onepassword_item" "item" {
  count = var.item == null ? 1 : 0
  vault = local.vault_uuid
  title = var.item_name
}

locals {
  # Use provided item or fetched item
  item_data = var.item != null ? var.item : data.onepassword_item.item[0]

  # Extract all fields from sections
  all_fields_list = var.section != null ? flatten([
    for s in local.item_data.section : [
      for f in s.field : { label = f.label, value = f.value }
    ] if s.label == var.section
  ]) : flatten([
    for s in local.item_data.section : [
      for f in s.field : { label = f.label, value = f.value }
    ]
  ])

  # Convert to map for easy access
  all_fields = { for f in local.all_fields_list : f.label => f.value }
}
