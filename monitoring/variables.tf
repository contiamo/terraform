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

variable "aws_tags" {
  type        = map(string)
  description = "Tags to apply to AWS resources. S3 bucket for Loki storage and IAM role for Loki service account."
  default = {
    "ManagedBy" = "Terraform"
  }
}
variable "oidc_provider_arn" {
  type        = string
  description = "The ARN of the OIDC provider for the EKS cluster. Will be used to define Loki service-account access to the storage S3 bucket."
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
  description = "The Slack Webhook URL for the Web Endpoint monitoring (blackbox exporter)"
  type        = string
  sensitive   = true
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
