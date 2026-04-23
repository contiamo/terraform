variable "target_cluster" {
  description = "Target cluster type. 'eks' uses IRSA for Loki bucket access; any other value provisions Loki with static AWS credentials and a PVC-backed storage class."
  type        = string
  default     = "eks"
}

variable "target_namespace" {
  type        = string
  description = "The namespace where the monitoring stack will be deployed."
  default     = "monitoring"
}

variable "kube_prometheus_version" {
  type        = string
  description = "kube-prometheus-stack Helm chart version."
}

variable "loki_version" {
  type        = string
  description = "Loki Helm chart version."
}

variable "loki_storage_bucket_name" {
  type        = string
  description = "The name of the S3 bucket where Loki will store logs. This bucket will be created by Terraform."
}

variable "loki_storage_bucket_secret_access_key" {
  type        = string
  description = "Secret access key for the S3 bucket where Loki stores logs. Used only when target_cluster != \"eks\"; EKS deployments authenticate via IRSA."
  sensitive   = true
  default     = ""
}

variable "loki_storage_bucket_access_key_id" {
  type        = string
  description = "Access key ID for the S3 bucket where Loki stores logs. Used only when target_cluster != \"eks\"; EKS deployments authenticate via IRSA."
  sensitive   = true
  default     = ""
}

variable "loki_storage_class_name" {
  type        = string
  description = "StorageClass for Loki PVCs (read/write/backend persistence). Only used when target_cluster != \"eks\"."
  default     = "gp2"
}

variable "aws_tags" {
  type        = map(string)
  description = "Tags to apply to AWS resources. S3 bucket for Loki storage and IAM role for Loki service account."
  default = {
    "ManagedBy" = "Terraform"
  }
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the OIDC provider for the EKS cluster (IRSA for the Loki service account). Leave empty for non-EKS deployments."
  default     = ""
}

variable "grafana_admin_user" {
  type        = string
  description = "The admin user for Grafana."
}

variable "grafana_admin_password" {
  type        = string
  description = "The admin password for Grafana."
  sensitive   = true
}

variable "grafana_pvc_size" {
  description = "The size of the Grafana Persistent Volume Claim."
  type        = string
}

variable "grafana_pvc_storage_class" {
  description = "StorageClass for the Grafana PVC. Leave empty to use the cluster's default StorageClass."
  type        = string
  default     = ""
}

variable "grafana_gateway_parent_ref" {
  description = "Gateway parentRef for the Grafana HTTPRoute (name/namespace/sectionName)."
  type = object({
    name         = string
    namespace    = string
    section_name = string
  })
}

variable "alert_manager_gateway_parent_ref" {
  description = "Gateway parentRef for the Alertmanager HTTPRoute (name/namespace/sectionName)."
  type = object({
    name         = string
    namespace    = string
    section_name = string
  })
}

variable "alert_manager_host" {
  description = "The host for Alert Manager"
  type        = string
}

variable "alert_manager_slack_webhook_url" {
  description = "The Slack Webhook URL for Alert Manager"
  type        = string
  sensitive   = true
}

variable "alert_manager_slack_webhook_url_web_endpoint_monitoring" {
  description = "Slack Webhook URL for the Web Endpoint monitoring (blackbox exporter). Falls back to alert_manager_slack_webhook_url when empty."
  type        = string
  sensitive   = true
  default     = ""
}

variable "grafana_host" {
  description = "The host for Grafana"
  type        = string
}

variable "blackbox_exporter_version" {
  type        = string
  description = "Blackbox exporter version."
  default     = "9.0.0"
}

variable "blackbox_exporter" {
  description = "Whether to install the Blackbox Exporter"
  type        = bool
  default     = true
}

variable "grafana_plugins" {
  description = "List of Grafana plugins to install."
  type        = list(string)
  default     = []
}

variable "grafana_oauth_enabled" {
  description = "Enable OAuth authentication for Grafana."
  type        = bool
  default     = false
}

variable "grafana_oauth_name" {
  description = "Display name for the OAuth provider (shown on the Grafana login page)."
  type        = string
  default     = "OAuth"
}

variable "grafana_oauth_client_id" {
  description = "OAuth client ID."
  type        = string
  default     = ""
}

variable "grafana_oauth_client_secret" {
  description = "OAuth client secret."
  type        = string
  sensitive   = true
  default     = ""
}

variable "grafana_oauth_scopes" {
  description = "OAuth scopes (space-separated)."
  type        = string
  default     = "openid email profile"
}

variable "grafana_oauth_auth_url" {
  description = "OAuth authorization URL."
  type        = string
  default     = ""
}

variable "grafana_oauth_token_url" {
  description = "OAuth token URL."
  type        = string
  default     = ""
}

variable "grafana_oauth_api_url" {
  description = "OAuth API / userinfo URL."
  type        = string
  default     = ""
}

variable "grafana_oauth_role_attribute_path" {
  description = "JMESPath expression used to resolve the Grafana role from the OAuth userinfo response."
  type        = string
  default     = ""
}

variable "grafana_oauth_role_attribute_strict" {
  description = "If true, deny login when the Grafana role cannot be extracted via role_attribute_path."
  type        = bool
  default     = false
}

variable "grafana_oauth_use_refresh_token" {
  description = "Enable refresh token usage for OAuth."
  type        = bool
  default     = true
}

variable "grafana_oauth_auto_login" {
  description = "Skip the Grafana login page and redirect directly to the OAuth provider."
  type        = bool
  default     = false
}

variable "grafana_oauth_skip_org_role_sync" {
  description = "Skip syncing org roles from the OAuth provider on login (preserves manual org assignments)."
  type        = bool
  default     = false
}

variable "grafana_auto_assign_org_id" {
  description = "Default org ID for new OAuth users. 0 falls back to Grafana's default org (1)."
  type        = number
  default     = 0
}

variable "grafana_extra_dashboard_providers" {
  description = "Additional dashboard providers for multi-org support. Each entry mounts a ConfigMap at /var/lib/grafana/dashboards/<name> and provisions into the specified org."
  type = list(object({
    name           = string
    org_id         = number
    configmap_name = string
  }))
  default = []
}
