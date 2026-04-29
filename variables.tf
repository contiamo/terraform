variable "crd_version" {
  description = "Gateway API CRD version to install (must have a matching file at crds/<version>-standard-install.yaml)"
  type        = string
  default     = "v1.5.1"
}
