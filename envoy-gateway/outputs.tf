output "namespace" {
  description = "The namespace where Envoy Gateway is deployed"
  value       = var.namespace
}

output "public_gateway_name" {
  description = "The name of the public gateway"
  value       = var.public_gateway_enabled ? var.public_gateway_name : null
}

output "internal_gateway_name" {
  description = "The name of the internal gateway"
  value       = var.internal_gateway_enabled ? var.internal_gateway_name : null
}

output "public_gateway_class" {
  description = "The name of the public GatewayClass"
  value       = var.public_gateway_enabled ? var.public_gateway_name : null
}

output "internal_gateway_class" {
  description = "The name of the internal GatewayClass"
  value       = var.internal_gateway_enabled ? var.internal_gateway_name : null
}

# Service names for DNS record creation
output "public_service_name" {
  description = "The Kubernetes service name for the public gateway (for DNS records)"
  value       = var.public_gateway_enabled ? "envoy-${var.namespace}-${var.public_gateway_name}" : null
}

output "internal_service_name" {
  description = "The Kubernetes service name for the internal gateway (for DNS records)"
  value       = var.internal_gateway_enabled ? "envoy-${var.namespace}-${var.internal_gateway_name}" : null
}
