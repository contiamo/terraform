# Monitoring stack

Sets up the standard Contiamo Grafana / Prometheus / Alertmanager / Loki stack on a Kubernetes cluster, fronted by Gateway API (Envoy Gateway). Log shipping is provided by Grafana Alloy (replaces promtail).

Two flavours are supported via `target_cluster`:

- **`eks` (default)** — Loki uses IRSA to talk to its S3 bucket; PVCs use the cluster's default StorageClass.
- **anything else (e.g. OTC CCE)** — Loki uses static AWS access keys (passed in via variables) and PVCs use the StorageClass given in `loki_storage_class_name` and `grafana_pvc_storage_class`.

The stack assumes:

- Gateway API + Envoy Gateway are already installed on the cluster (use the `envoy-gateway` and `gateway-api-crds` modules).
- A Gateway resource exists with HTTPS listener sections that the caller can reference for Grafana and Alertmanager.

## EKS usage

```hcl
module "monitoring" {
  # contiamo-release-please-bump-start
  source = "github.com/contiamo/terraform//monitoring?ref=v0.20.2"
  # contiamo-release-please-bump-end

  target_namespace        = "monitoring"
  kube_prometheus_version = "83.4.3"
  loki_version            = "6.23.0"
  loki_storage_bucket_name = "my-loki-storage"
  oidc_provider_arn       = module.eks.oidc_provider_arn

  grafana_admin_user     = "contiamo"
  grafana_admin_password = random_password.grafana.result
  grafana_pvc_size       = "10Gi"

  grafana_gateway_parent_ref = {
    name         = "envoy-public"
    namespace    = "envoy-gateway-system"
    section_name = "https-example-com"
  }
  grafana_host = "grafana.example.com"

  alert_manager_gateway_parent_ref = {
    name         = "envoy-public"
    namespace    = "envoy-gateway-system"
    section_name = "https-example-com"
  }
  alert_manager_host              = "alertmanager.example.com"
  alert_manager_slack_webhook_url = var.slack_webhook

  aws_tags = {
    "ManagedBy" = "Terraform"
  }
}
```

## Non-EKS usage (e.g. OTC CCE)

```hcl
module "monitoring" {
  # contiamo-release-please-bump-start
  source = "github.com/contiamo/terraform//monitoring?ref=v0.20.2"
  # contiamo-release-please-bump-end

  target_cluster                        = "otc"
  target_namespace                      = "monitoring"
  kube_prometheus_version               = "83.4.3"
  loki_version                          = "6.23.0"
  loki_storage_bucket_name              = "my-loki-storage"
  loki_storage_bucket_access_key_id     = aws_iam_access_key.loki.id
  loki_storage_bucket_secret_access_key = aws_iam_access_key.loki.secret
  loki_storage_class_name               = "csi-disk"

  grafana_admin_user        = "contiamo"
  grafana_admin_password    = random_password.grafana.result
  grafana_pvc_size          = "10Gi"
  grafana_pvc_storage_class = "csi-disk"

  grafana_gateway_parent_ref = {
    name         = "envoy-public"
    namespace    = "envoy-gateway-system"
    section_name = "https-example-com"
  }
  grafana_host = "grafana.example.com"

  alert_manager_gateway_parent_ref = {
    name         = "envoy-tailscale"
    namespace    = "envoy-gateway-system"
    section_name = "https-example-com"
  }
  alert_manager_host              = "alertmanager.example.com"
  alert_manager_slack_webhook_url = var.slack_webhook
}
```

## Optional features

### Grafana plugins

```hcl
grafana_plugins = ["yesoreyeram-infinity-datasource"]
```

### OAuth / OIDC sign-in

Set `grafana_oauth_enabled = true` and provide the standard generic-OAuth fields. The `grafana_oauth_role_attribute_path` JMESPath expression maps OAuth roles to Grafana roles, e.g.:

```hcl
grafana_oauth_role_attribute_path = "contains(roles[*], 'grafana-admin') && 'Admin' || contains(roles[*], 'grafana-viewer') && 'Viewer'"
grafana_oauth_role_attribute_strict = true
```

### Multi-org dashboard provisioning

`grafana_extra_dashboard_providers` mounts additional dashboard ConfigMaps into Grafana and provisions them into the specified org. Use this to ship dashboards into orgs other than the default Contiamo org.

```hcl
grafana_extra_dashboard_providers = [
  { name = "ewr-genai", org_id = 2, configmap_name = "langfuse-ewr-dev-metrics-dashboard" }
]
```
