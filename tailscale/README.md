# Tailscale Module

This module installs a Tailscale Subnet Router for a K8S cluster

## Instructions:

### Reference In Another TF Project:

```terraform
module "tailscale" {
  source = "git@github.com:contiamo/terraform.git//tailscale"
  tailscale_auth_key = var.tailscale_auth_key
  create_tailscale_auth_key_secret = var.create_tailscale_auth_key_secret
  image_tag = "v1.34.1"
}
```
