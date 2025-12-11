variable "chart_version" {
  description = "Envoy Gateway Helm chart version"
  type        = string
  default     = "v1.5.5"
}

variable "namespace" {
  description = "Kubernetes namespace for Envoy Gateway"
  type        = string
  default     = "envoy-gateway-system"
}

variable "replicas" {
  description = "Number of Envoy proxy replicas"
  type        = number
  default     = 2
}

variable "cert_manager_cluster_issuer" {
  description = "Default cert-manager ClusterIssuer name for TLS certificates (can be overridden per gateway)"
  type        = string
  default     = "letsencrypt-production-route53"
}

variable "gateways" {
  description = "List of gateway configurations. Each gateway creates a GatewayClass, EnvoyProxy, Gateway, and HTTPRoute."
  type = list(object({
    name            = string                # Gateway name (e.g., "envoy-public")
    enabled         = optional(bool, true)  # Whether to create this gateway
    envoyproxy_name = optional(string)      # Custom EnvoyProxy name (defaults to "{name}-proxy")
    listeners = list(object({
      domain = string # Domain pattern (e.g., "*.ctmo.io")
      name   = string # Listener name suffix (e.g., "ctmo" -> "http-ctmo", "https-ctmo")
    }))
    lb_annotations      = map(string)           # LoadBalancer service annotations
    tls_secret_suffix   = optional(string)      # TLS secret suffix pattern (default: "-tls-{idx}")
    cert_manager_issuer = optional(string)      # Override default cert-manager issuer
  }))

  validation {
    condition     = length(var.gateways) > 0
    error_message = "At least one gateway must be configured."
  }
}
