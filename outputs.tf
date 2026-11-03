output "namespace" {
  description = "Namespace where the Karpenter controller is deployed."
  value       = var.namespace
}

output "release_name" {
  description = "Helm release name."
  value       = var.release_name
}

output "version" {
  description = "Karpenter version installed by this module."
  value       = var.chart_version
}
