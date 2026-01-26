data "onepassword_vault" "vault" {
  name = var.vault_name
}

data "onepassword_item" "item" {
  vault = data.onepassword_vault.vault.uuid
  title = var.item_name
}

locals {
  # Extract fields - optionally filter by section
  fields = var.section != null ? {
    for f in flatten([
      for s in data.onepassword_item.item.section : s.field if s.label == var.section
    ]) : f.label => f.value
  } : {
    for f in flatten([
      for s in data.onepassword_item.item.section : s.field
    ]) : f.label => f.value
  }
}
