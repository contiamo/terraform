variable "namespace" {
  type        = string
  description = "Kubernetes namespace for the Coder control plane. Workspaces are created in this namespace as well unless `workspace_namespaces` adds more."
  default     = "coder"
}

variable "create_namespace" {
  type        = bool
  description = "Create the namespace. Set to false when the caller manages it, e.g. because the database Secret has to exist in it before this module runs."
  default     = true
}

variable "namespace_labels" {
  type        = map(string)
  description = "Labels applied to the namespace when `create_namespace` is true."
  default     = {}
}

variable "chart_version" {
  type        = string
  description = "Version of the coder-v2/coder Helm chart. Chart and app versions are identical."
  default     = "2.37.3"
}

variable "access_host" {
  type        = string
  description = "Hostname of the Coder control plane, e.g. coder.example.com. Becomes CODER_ACCESS_URL (https) and the HTTPRoute hostname."
}

variable "wildcard_access_host" {
  type        = string
  description = <<-EOT
    Wildcard hostname for subdomain-based workspace apps, e.g. *.coder.example.com. Becomes CODER_WILDCARD_ACCESS_URL.
    When set, the chart creates a ListenerSet on the parent Gateway with its own cert-manager certificate for the wildcard,
    an HTTP listener with a 301 redirect to HTTPS, and attaches the wildcard hostname to the Coder HTTPRoute.
    Leave null for path-based apps only.
  EOT
  default     = null

  validation {
    condition     = var.wildcard_access_host == null || can(regex("^\\*\\.", var.wildcard_access_host))
    error_message = "wildcard_access_host must start with '*.' (e.g. *.coder.example.com)."
  }
}

variable "gateway_parent_ref" {
  type = object({
    name         = string
    namespace    = string
    section_name = string
  })
  description = "Gateway parentRef for the Coder HTTPRoute (name/namespace/sectionName). The section is the HTTPS listener whose wildcard cert covers `access_host`. The ListenerSet for `wildcard_access_host` attaches to the same Gateway."
}

variable "cert_manager_cluster_issuer" {
  type        = string
  description = "cert-manager ClusterIssuer that can issue a certificate for `wildcard_access_host` (a DNS-01 issuer; HTTP-01 cannot validate wildcards). Required when `wildcard_access_host` is set."
  default     = null

  validation {
    condition     = var.wildcard_access_host == null || var.cert_manager_cluster_issuer != null
    error_message = "cert_manager_cluster_issuer is required when wildcard_access_host is set."
  }
}

variable "listenerset_annotations" {
  type        = map(string)
  description = "Extra annotations on the ListenerSet. Use this to copy the parent Gateway's `external-dns.kubernetes.io/target` annotation on clusters where the Gateway carries one (dual-homed load balancers)."
  default     = {}
}

variable "database" {
  type = object({
    mode        = optional(string, "external")
    secret_name = string
    secret_key  = optional(string, "url")
  })
  description = <<-EOT
    Postgres connection for Coder.
    mode: only "external" today (an existing Postgres such as RDS). An in-cluster mode backed by CloudNativePG is planned.
    secret_name: Kubernetes Secret in `namespace` holding the connection URL. The module does not create it.
    secret_key: key inside the Secret holding a full URL of the form postgres://user:password@host:5432/dbname?sslmode=require.
  EOT

  validation {
    condition     = var.database.mode == "external"
    error_message = "database.mode must be \"external\". In-cluster (CloudNativePG) mode is not implemented yet."
  }
}

variable "oidc" {
  type = object({
    issuer_url                = string
    client_id                 = string
    client_secret_secret_name = string
    client_secret_secret_key  = optional(string, "client-secret")
    email_domains             = optional(list(string), [])
    sign_in_text              = optional(string, "OpenID Connect")
    icon_url                  = optional(string, null)
    scopes                    = optional(list(string), ["openid", "profile", "email"])
    allow_signups             = optional(bool, true)
    disable_password_auth     = optional(bool, false)
  })
  description = <<-EOT
    OIDC login. Null (default) keeps built-in password login only.
    client_secret_secret_name / client_secret_secret_key: existing Secret in `namespace` holding the OIDC client secret.
    email_domains: restrict sign-ups to these email domains.
    disable_password_auth: once OIDC is verified to work, set true to remove the password form. Keep an OIDC admin before doing so.
  EOT
  default     = null
}

variable "proxy_trusted_origins" {
  type        = list(string)
  description = "CIDRs of the reverse proxies in front of Coder (the Envoy proxy pods). When non-empty, Coder trusts X-Forwarded-For from these origins so audit logs and rate limits see client IPs instead of proxy IPs."
  default     = []
}

variable "replica_count" {
  type        = number
  description = "Number of coderd replicas. Multiple replicas share the same Postgres and are safe behind one Service."
  default     = 1
}

variable "resources" {
  type = object({
    requests = object({ cpu = string, memory = string })
    limits   = object({ cpu = string, memory = string })
  })
  description = "Resources for the coderd container. Coder sizes the control plane at roughly 2 vCPU / 4 GiB per 250 concurrent users."
  default = {
    requests = { cpu = "500m", memory = "1Gi" }
    limits   = { cpu = "2000m", memory = "4Gi" }
  }
}

variable "workspace_namespaces" {
  type        = list(string)
  description = "Additional namespaces in which the Coder ServiceAccount may create workspace pods and PVCs. Coder's own namespace is always permitted."
  default     = []
}

variable "telemetry_enabled" {
  type        = bool
  description = "Send anonymous usage telemetry to Coder (CODER_TELEMETRY_ENABLE)."
  default     = false
}

variable "extra_env" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Additional plain environment variables for coderd (any CODER_* setting not covered by a dedicated variable)."
  default     = []
}

variable "extra_helm_values" {
  type        = string
  description = "Extra Helm values as a YAML string, merged last over the module-generated values. Escape hatch for chart settings without a dedicated variable."
  default     = ""
}
