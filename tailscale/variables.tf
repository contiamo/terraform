variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace to deploy to"
  default     = "tailscale"
}
variable "tailscale_auth_key" {
  type        = string
  description = "Tailscale auth key"
}
variable "create_tailscale_auth_key_secret" {
  type        = bool
  description = "Determines whether to create a Kubernetes secret for the Tailscale auth key.\nSet to false if you've already created the secret manually"
  default     = true
}
variable "image_name" {
  type        = string
  description = "Tailscale image name"
  default     = "ghcr.io/tailscale/tailscale"
}
variable "image_tag" {
  type        = string
  description = "Tailscale image tag"
  default     = "v1.34.1"
}
variable "k8s_cluster_service_cidr" {
  type        = string
  description = "Kubernetes cluster service CIDR"
}
variable "k8s_cluster_pod_cidr" {
  type        = string
  description = "Kubernetes cluster pod CIDR"
}
