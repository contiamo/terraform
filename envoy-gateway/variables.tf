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

# Public Gateway Configuration
variable "public_gateway_enabled" {
  description = "Enable public gateway"
  type        = bool
  default     = true
}

variable "public_gateway_name" {
  description = "Name for the public gateway resources"
  type        = string
  default     = "envoy-public"
}

variable "public_envoyproxy_name" {
  description = "Name for the public EnvoyProxy resource. If not set, defaults to '{public_gateway_name}-proxy'"
  type        = string
  default     = null
}

variable "public_listeners" {
  description = "List of listener configurations for the public gateway. Each item should have 'domain' and 'name' keys. If not set, uses public_domains with numeric indices."
  type = list(object({
    domain = string
    name   = string
  }))
  default = null
}

variable "public_domains" {
  description = "List of domains for the public gateway (e.g., ['*.example.com']). Used only if public_listeners is not set."
  type        = list(string)
  default     = []
}

variable "public_lb_annotations" {
  description = "Annotations for the public load balancer service"
  type        = map(string)
}

variable "public_tls_secret_suffix" {
  description = "Suffix pattern for TLS secrets. Use '{domain}' as placeholder for domain name, or '{idx}' for index. Default: '-tls-{idx}'"
  type        = string
  default     = "-tls-{idx}"
}

# Internal/Tailscale Gateway Configuration
variable "internal_gateway_enabled" {
  description = "Enable internal/tailscale gateway"
  type        = bool
  default     = true
}

variable "internal_gateway_name" {
  description = "Name for the internal gateway resources"
  type        = string
  default     = "envoy-tailscale"
}

variable "internal_envoyproxy_name" {
  description = "Name for the internal EnvoyProxy resource. If not set, defaults to '{internal_gateway_name}-proxy'"
  type        = string
  default     = null
}

variable "internal_listeners" {
  description = "List of listener configurations for the internal gateway. Each item should have 'domain' and 'name' keys. If not set, uses internal_domains with numeric indices."
  type = list(object({
    domain = string
    name   = string
  }))
  default = null
}

variable "internal_domains" {
  description = "List of domains for the internal gateway (e.g., ['*.internal.example.com']). Used only if internal_listeners is not set."
  type        = list(string)
  default     = []
}

variable "internal_lb_annotations" {
  description = "Annotations for the internal load balancer service"
  type        = map(string)
}

variable "internal_tls_secret_suffix" {
  description = "Suffix pattern for TLS secrets. Use '{domain}' as placeholder for domain name, or '{idx}' for index. Default: '-tls-{idx}'"
  type        = string
  default     = "-tls-{idx}"
}

# Certificate Manager
variable "cert_manager_cluster_issuer" {
  description = "The cert-manager ClusterIssuer name for TLS certificates"
  type        = string
  default     = "letsencrypt-production-route53"
}
