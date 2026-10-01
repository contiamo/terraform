output "namespace" {
  description = "Kubernetes namespace where Coder is deployed"
  value       = local.namespace
}

output "url" {
  description = "URL of the Coder control plane"
  value       = "https://${var.access_host}"
}

output "wildcard_access_url" {
  description = "Wildcard hostname for subdomain-based workspace apps, null when disabled"
  value       = var.wildcard_access_host
}

output "internal_url" {
  description = "In-cluster URL of the Coder Service (plain HTTP, TLS terminates at the Gateway)"
  value       = "http://coder.${local.namespace}.svc.cluster.local"
}

output "service_account_name" {
  description = "ServiceAccount used by coderd and its built-in provisioner; grant it RBAC in extra workspace namespaces if needed"
  value       = "coder"
}

output "listenerset_name" {
  description = "Name of the ListenerSet serving the wildcard hostname, null when disabled"
  value       = local.wildcard_enabled ? local.listenerset_name : null
}

output "chart_version" {
  description = "Deployed Coder Helm chart version"
  value       = helm_release.coder.version
}
