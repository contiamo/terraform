# Monitoring Stack for EKS

This module sets up Grafana, Prometheus, Loki and Promtail stack.
This is all you need to monitor your EKS cluster.

## Usage:

```hcl
module "monitoring" {
  source                            = "github.com/contiamo/terraform//monitoring"
  target_namespace                  = "monitoring"
  kube_prometheus_version           = "60.2.0"
  promtail_version                  = "6.16.0"
  loki_version                      = "6.6.3"
  loki_storage_bucket_name          = "my-loki-storage" # this bucket will be created for you.
  oidc_provider_arn                 = module.eks.oidc_provider_arn # If you used the EKS module to create your cluster simply use this value.
  grafana_pvc_size                  = "50Gi"
  grafana_ingress_class_name        = "nginx-internal" # the name of your NGINX ingress class
  cert_manager_cluster_issuer_name  = local.cert_manager_cluster_issuer_name
  grafana_host                      = "grafana.internal.ctmo.io"
  grafana_admin_user                = "contiamo"
  grafana_admin_password            = random_password.grafana.result # Generate your password in TF or use your own value here.
  aws_tags = {
    "ManagedBy"          = "Terraform",
  }
}
```
