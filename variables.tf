variable "langfuse_host" {
  type        = string
  description = "The hostname for Langfuse ingress (e.g., langfuse.example.com)"
}

variable "langfuse_namespace" {
  type        = string
  description = "The Kubernetes namespace where Langfuse will be deployed"
  default     = "langfuse"
}

variable "admin_email" {
  type        = string
  description = "The email address for the initial admin user"
}

variable "org_id" {
  type        = string
  description = "The organisation ID for Langfuse initialisation"
}

variable "org_name" {
  type        = string
  description = "The organisation name for Langfuse initialisation"
}

variable "project_id" {
  type        = string
  description = "The project ID for Langfuse initialisation"
}

variable "project_name" {
  type        = string
  description = "The project name for Langfuse initialisation"
}

variable "chart_version" {
  type        = string
  description = "The version of the Langfuse Helm chart to deploy"
  default     = "1.0.0"
}

variable "clickhouse_volume_size" {
  type        = string
  description = "Storage size for ClickHouse persistent volume"
  default     = "50Gi"
}

variable "s3_volume_size" {
  type        = string
  description = "Storage size for S3/MinIO persistent volume"
  default     = "50Gi"
}

variable "ingress_class_name" {
  type        = string
  description = "The Ingress class name to use for Langfuse ingress"
  default     = "nginx"
}

variable "cert_manager_cluster_issuer" {
  type        = string
  description = "The cert-manager ClusterIssuer to use for TLS certificates"
  default     = "letsencrypt-production"
}
