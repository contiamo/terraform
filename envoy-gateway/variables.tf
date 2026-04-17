variable "chart_version" {
  description = <<-EOT
    Envoy Gateway Helm chart version. Drives both the controller (gateway-helm)
    and the bundled Envoy Gateway CRDs (gateway-crds-helm). The Gateway API CRD
    version pin is independent and managed by the gateway-api-crds module.

    Must be one of the versions tracked in locals.tf
    (chart_version_to_envoy_crds_map). New versions are added automatically by
    the daily update-envoy-gateway-crds workflow, or manually via:
      ./envoy-gateway/scripts/update-envoy-crds.sh <new-version>

    See the Envoy Gateway compatibility matrix:
    https://gateway.envoyproxy.io/news/releases/matrix/
  EOT
  type        = string
  default     = "v1.7.2"
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
    name            = string               # Gateway name (e.g., "envoy-public")
    enabled         = optional(bool, true) # Whether to create this gateway
    envoyproxy_name = optional(string)     # Custom EnvoyProxy name (defaults to "{name}-proxy")
    listeners = list(object({
      domain = string # Domain pattern (e.g., "*.ctmo.io")
      name   = string # Listener name suffix (e.g., "ctmo" -> "http-ctmo", "https-ctmo")
    }))
    lb_annotations      = map(string)      # LoadBalancer service annotations
    tls_secret_suffix   = optional(string) # TLS secret suffix pattern (default: "-tls-{idx}")
    cert_manager_issuer = optional(string) # Override default cert-manager issuer
  }))

  validation {
    condition     = length(var.gateways) > 0
    error_message = "At least one gateway must be configured."
  }
}
