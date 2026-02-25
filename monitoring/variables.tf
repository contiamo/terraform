variable "target_cluster" {
  description = "Target cluster type (eks or other). Controls Loki S3 auth method: EKS uses IRSA, non-EKS uses IAM access keys."
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
  description = "ube-prometheus-stack Helm chart version."
}

variable "loki_version" {
  type        = string
  description = "Loki Helm chart version."
}

variable "loki_storage_bucket_name" {
  type        = string
  description = "The name of the S3 bucket where Loki will store logs. This bucket will be created by Terraform."
}

variable "aws_tags" {
  type        = map(string)
  description = "Tags to apply to AWS resources. S3 bucket  for Loki stprage and IAM rile for Loki service account."
  default = {
    "ManagedBy" = "Terraform"
  }
}
variable "oidc_provider_arn" {
  type        = string
  description = "The ARN of the OIDC provider for the EKS cluster. Will be used to define Loki service-account access to the storage S3 bucket. Required when target_cluster = eks."
  default     = ""
}

variable "loki_storage_bucket_secret_access_key" {
  type        = string
  description = "The secret access key for the S3 bucket where Loki will store logs (used for non-EKS deployments)."
  sensitive   = true
  default     = ""
}

variable "loki_storage_bucket_access_key_id" {
  type        = string
  description = "The access key ID for the S3 bucket where Loki will store logs (used for non-EKS deployments)."
  sensitive   = true
  default     = ""
}

variable "loki_storage_class_name" {
  type        = string
  description = "The storage class name for Loki PVCs (used for non-EKS deployments)."
  default     = "gp2"
}

variable "grafana_admin_user" {
  type        = string
  description = "The admin user for Grafana."
}

variable "grafana_admin_password" {
  type        = string
  description = "The admin password for Grafana."
}
variable "grafana_pvc_size" {
  description = "The size of the Grafana Persistent Volume Claim"
  type        = string
}

variable "grafana_ingress_class_name" {
  description = "The class name for the Grafana Ingress"
  type        = string
}
variable "alert_manager_ingress_class_name" {
  description = "The class name for the Alert Manager Ingress"
  type        = string
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
  description = "The Slack Webhook URL for the Web Endpoint monitoring (blackbox exporter)"
  type        = string
  sensitive   = true
}
variable "cert_manager_cluster_issuer_name" {
  description = "The name of the Cert Manager Cluster Issuer"
  type        = string
}

variable "grafana_host" {
  description = "The host for Grafana"
  type        = string
}
variable "promtail_version" {
  type        = string
  description = "Promtail version."
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

# Grafana plugins
variable "grafana_plugins" {
  description = "List of Grafana plugins to install"
  type        = list(string)
  default     = []
}

# Grafana OAuth/OIDC configuration
variable "grafana_oauth_enabled" {
  description = "Enable OAuth authentication for Grafana"
  type        = bool
  default     = false
}

variable "grafana_oauth_name" {
  description = "Display name for OAuth provider (shown on login page)"
  type        = string
  default     = "OAuth"
}

variable "grafana_oauth_client_id" {
  description = "OAuth client ID"
  type        = string
  default     = ""
}

variable "grafana_oauth_client_secret" {
  description = "OAuth client secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "grafana_oauth_scopes" {
  description = "OAuth scopes (space-separated)"
  type        = string
  default     = "openid email profile"
}

variable "grafana_oauth_auth_url" {
  description = "OAuth authorization URL"
  type        = string
  default     = ""
}

variable "grafana_oauth_token_url" {
  description = "OAuth token URL"
  type        = string
  default     = ""
}

variable "grafana_oauth_api_url" {
  description = "OAuth API/userinfo URL"
  type        = string
  default     = ""
}

variable "grafana_oauth_role_attribute_path" {
  description = "JMESPath expression to use for Grafana role lookup"
  type        = string
  default     = ""
}

variable "grafana_oauth_role_attribute_strict" {
  description = "If enabled, denies user login if the Grafana role cannot be extracted using role_attribute_path"
  type        = bool
  default     = false
}

variable "grafana_oauth_use_refresh_token" {
  description = "Enable refresh token usage for OAuth"
  type        = bool
  default     = true
}

variable "grafana_oauth_auto_login" {
  description = "Skip Grafana login page and redirect directly to OAuth provider"
  type        = bool
  default     = false
}
