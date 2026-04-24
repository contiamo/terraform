variable "chart_version" {
  description = <<-EOT
    1Password Connect Helm chart version. Drives both the Connect server and
    Operator images plus the bundled OnePasswordItem CRD.

    Must be one of the versions tracked in locals.tf (chart_version_to_crds_map).
    New versions are added automatically by the daily
    update-onepassword-connect-crds workflow, or manually via:
      ./onepassword-connect/scripts/update-onepassword-crds.sh <new-version>

    See the chart on GitHub:
    https://github.com/1Password/connect-helm-charts
  EOT
  type        = string
  default     = "2.4.1"
}

variable "namespace" {
  description = "Kubernetes namespace for 1Password Connect / Operator."
  type        = string
  default     = "1password"
}

variable "release_name" {
  description = <<-EOT
    Helm release name. Defaults to `connect-server` to preserve the release
    name on Contiamo EKS (where this module was first adopted). Override only
    when bootstrapping a fresh cluster.
  EOT
  type        = string
  default     = "connect-server"
}

variable "install_connect_server" {
  description = "Whether to deploy the Connect server component (maps to `connect.create`)."
  type        = bool
  default     = true
}

variable "install_operator" {
  description = "Whether to deploy the Operator component (maps to `operator.create`)."
  type        = bool
  default     = true
}

variable "operator_auth_method" {
  description = <<-EOT
    Operator authentication method.
      * `connect`         — Operator talks to an in-cluster Connect server
                            using a Connect API token (`operator_token`).
      * `service-account` — Operator talks directly to 1Password's cloud
                            using a Service Account token
                            (`operator_service_account_token`). No Connect
                            server required.
  EOT
  type        = string
  default     = "connect"
  validation {
    condition     = contains(["connect", "service-account"], var.operator_auth_method)
    error_message = "operator_auth_method must be 'connect' or 'service-account'."
  }
}

variable "connect_credentials_base64" {
  description = <<-EOT
    Base64-encoded contents of the `1password-credentials.json` file that
    authenticates the Connect server to 1Password's cloud. Required when
    `install_connect_server = true`.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "operator_token" {
  description = <<-EOT
    1Password Connect API token used by the Operator when
    `operator_auth_method = "connect"`. Required in that configuration.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "operator_service_account_token" {
  description = <<-EOT
    1Password Service Account token used by the Operator when
    `operator_auth_method = "service-account"`. Required in that configuration.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "host" {
  description = <<-EOT
    Hostname to expose the Connect server at via Gateway API. When null, no
    HTTPRoute is created (useful for operator-only deployments or clusters
    where the Connect server is consumed in-cluster only).
  EOT
  type        = string
  default     = null
}

variable "gateway_name" {
  description = "Name of the Gateway resource the HTTPRoute attaches to. Required when `host` is set."
  type        = string
  default     = null
}

variable "gateway_namespace" {
  description = "Namespace of the Gateway resource. Required when `host` is set."
  type        = string
  default     = null
}

variable "gateway_section_name" {
  description = "sectionName of the Gateway listener the HTTPRoute attaches to. Required when `host` is set."
  type        = string
  default     = null
}

variable "extra_values" {
  description = <<-EOT
    Additional Helm values merged on top of the module's computed values.
    Use for chart-specific tuning (resources, tolerations, nodeSelector,
    etc.) not exposed as first-class variables. Deep-merged, so keys set by
    the module can still be overridden here.
  EOT
  type        = any
  default     = {}
}
