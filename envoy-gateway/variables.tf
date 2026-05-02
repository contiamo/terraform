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

variable "enable_grafana_dashboards" {
  description = <<-EOT
    Install the upstream Envoy Gateway Grafana dashboards as a ConfigMap in
    `monitoring_namespace`, labelled for kube-prometheus-stack's Grafana
    sidecar to pick up. Dashboards are vendored under `dashboards/` and pinned
    to chart_version. Refresh with scripts/update-envoy-dashboards.sh.
  EOT
  type        = bool
  default     = true
}

variable "enable_metrics_scraping" {
  description = <<-EOT
    Create a ServiceMonitor for the Envoy Gateway controller and a PodMonitor
    for the Envoy proxy fleet so Prometheus scrapes both control-plane and
    data-plane metrics. Requires the Prometheus Operator CRDs
    (monitoring.coreos.com/v1) to be present in the cluster — typically via
    kube-prometheus-stack.
  EOT
  type        = bool
  default     = true
}

variable "monitoring_namespace" {
  description = "Namespace where kube-prometheus-stack runs. Hosts the dashboards ConfigMap and the ServiceMonitor / PodMonitor."
  type        = string
  default     = "monitoring"
}

variable "dashboard_label" {
  description = "Label key the Grafana sidecar watches. Default matches kube-prometheus-stack's sidecar default (`grafana_dashboard`)."
  type        = string
  default     = "grafana_dashboard"
}

variable "dashboard_label_value" {
  description = "Value paired with `dashboard_label`. Default matches the kube-prometheus-stack sidecar default (`1`)."
  type        = string
  default     = "1"
}

variable "service_monitor_release_label" {
  description = "Label key on ServiceMonitor / PodMonitor used by the Prometheus CR's selector. kube-prometheus-stack defaults to `release`."
  type        = string
  default     = "release"
}

variable "service_monitor_release_value" {
  description = "Value paired with `service_monitor_release_label` so Prometheus picks up the monitors. kube-prometheus-stack uses the Helm release name (typically `monitoring-stack`)."
  type        = string
  default     = "monitoring-stack"
}

variable "gateways" {
  description = "List of gateway configurations. Each gateway creates a GatewayClass, EnvoyProxy, Gateway, and HTTPRoute."
  type = list(object({
    name            = string               # Gateway name (e.g., "envoy-public")
    enabled         = optional(bool, true) # Whether to create this gateway
    envoyproxy_name = optional(string)     # Custom EnvoyProxy name (defaults to "{name}-proxy")
    listeners = list(object({
      domain          = string           # Domain pattern (e.g., "*.ctmo.io")
      name            = string           # Listener name suffix (e.g., "ctmo" -> "http-ctmo", "https-ctmo")
      tls_secret_name = optional(string) # Override the auto-generated TLS secret name. Use when reusing a Secret managed elsewhere (e.g. by an existing nginx Ingress) to avoid a fresh ACME issuance during cutover. If unset, the secret name is derived from `tls_secret_suffix`.
    }))
    lb_annotations      = map(string)               # LoadBalancer service annotations
    gateway_annotations = optional(map(string), {}) # Extra annotations applied to the Gateway resource (merged with the cert-manager annotation)
    tls_secret_suffix   = optional(string)          # TLS secret suffix pattern (default: "-tls-{idx}")
    cert_manager_issuer = optional(string)          # Override default cert-manager issuer
  }))

  validation {
    condition     = length(var.gateways) > 0
    error_message = "At least one gateway must be configured."
  }
}
