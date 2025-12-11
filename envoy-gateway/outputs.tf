output "namespace" {
  description = "The namespace where Envoy Gateway is deployed"
  value       = var.namespace
}

output "gateways" {
  description = "Map of gateway configurations with their service names"
  value = {
    for name, gw in local.enabled_gateways : name => {
      name            = name
      gateway_class   = name
      envoyproxy_name = coalesce(gw.envoyproxy_name, "${name}-proxy")
      service_name    = "envoy-${var.namespace}-${name}"
      listeners       = gw.listeners
    }
  }
}

# Convenience outputs for common use cases
output "gateway_names" {
  description = "List of enabled gateway names"
  value       = keys(local.enabled_gateways)
}

output "service_names" {
  description = "Map of gateway names to their Kubernetes service names (for DNS records)"
  value = {
    for name, _ in local.enabled_gateways : name => "envoy-${var.namespace}-${name}"
  }
}
