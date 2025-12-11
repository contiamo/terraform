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

variable "public_domains" {
  description = "List of domains for the public gateway (e.g., ['*.example.com'])"
  type        = list(string)
}

variable "public_lb_annotations" {
  description = "Annotations for the public load balancer service"
  type        = map(string)
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

variable "internal_domains" {
  description = "List of domains for the internal gateway (e.g., ['*.internal.example.com'])"
  type        = list(string)
}

variable "internal_lb_annotations" {
  description = "Annotations for the internal load balancer service"
  type        = map(string)
}

# Certificate Manager
variable "cert_manager_cluster_issuer" {
  description = "The cert-manager ClusterIssuer name for TLS certificates"
  type        = string
  default     = "letsencrypt-production-route53"
}
