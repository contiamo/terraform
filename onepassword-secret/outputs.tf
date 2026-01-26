output "value" {
  description = "The secret field value"
  value       = local.fields[var.field]
  sensitive   = true
}
