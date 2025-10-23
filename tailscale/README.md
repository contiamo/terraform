# Tailscale Module

This module installs a Tailscale Subnet Router for a K8S cluster

## Instructions:

### Reference In Another TF Project:

```terraform
module "tailscale" {
  # To reference as a private repo use "git@github.com:/contiamo...:
  # source = "git@github.com:contiamo/terraform.git//tailscale"
  # contiamo-release-please-bump-start
  source = "github.com/contiamo/terraform//tailscale?ref=v0.8.1"
  # contiamo-release-please-bump-end
  tailscale_auth_key = var.tailscale_auth_key
  create_tailscale_auth_key_secret = var.create_tailscale_auth_key_secret
  image_tag = "v1.54.1"
  k8s_cluster_pod_cidr = "<YOUR cluster pod CIDR>"
  k8s_cluster_service_cidr = "<YOUR cluster service CIDR>"
}
```
