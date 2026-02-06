output "value" {
  description = "The secret field value (requires 'field' variable to be set)"
  value       = var.field != null ? local.all_fields[var.field] : null
  sensitive   = true
}

output "all_fields" {
  description = "Map of all field labels to their values (from the specified section, or all sections if section is null)"
  value       = local.all_fields
  sensitive   = true
}

output "item_uuid" {
  description = "The UUID of the 1Password item (useful for debugging or chaining)"
  value       = local.item_data.uuid
}

output "vault_uuid" {
  description = "The UUID of the 1Password vault (useful for passing to other module instances)"
  value       = var.item != null ? null : local.vault_uuid
}
