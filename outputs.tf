output "namespace" {
  description = "Namespace where 1Password Connect / Operator is deployed."
  value       = var.namespace
}

output "release_name" {
  description = "Helm release name."
  value       = var.release_name
}

output "connect_service_name" {
  description = "Kubernetes Service name for the Connect server (fixed by the chart's `connect.applicationName` default). See `connect_http_url` for the full in-cluster URL."
  value       = "onepassword-connect"
}

output "connect_http_url" {
  description = "In-cluster base URL for the Connect API."
  value       = "http://onepassword-connect.${var.namespace}.svc:8080"
}

output "host" {
  description = "External hostname for the Connect server (null when no HTTPRoute is created)."
  value       = var.host
}
