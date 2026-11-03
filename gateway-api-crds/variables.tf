variable "crd_version" {
  # Before raising this default (or pinning a newer minor in a caller), check
  # that the Envoy Gateway release running on the clusters is built against
  # this Gateway API minor: https://gateway.envoyproxy.io/news/releases/matrix/
  # See "Envoy Gateway compatibility" in README.md.
  description = "Gateway API CRD version to install (must have a matching file at crds/<version>-standard-install.yaml). Must be a minor supported by the Envoy Gateway release on the cluster; see README."
  type        = string
  default     = "v1.6.2"
}
