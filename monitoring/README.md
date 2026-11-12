# Monitoring stack

Sets up the standard Contiamo Grafana / Prometheus / Alertmanager / Loki stack on a Kubernetes cluster, fronted by Gateway API (Envoy Gateway). Log shipping is provided by Grafana Alloy (replaces promtail).

Two flavours are supported via `target_cluster`:

- **`eks` (default)** — Loki uses IRSA to talk to its S3 bucket; PVCs use the cluster's default StorageClass.
- **anything else (e.g. OTC CCE)** — Loki uses static AWS access keys (passed in via variables) and PVCs use the StorageClass given in `loki_storage_class_name` and `grafana_pvc_storage_class`.

The stack assumes:

- Gateway API + Envoy Gateway are already installed on the cluster (use the `envoy-gateway` and `gateway-api-crds` modules).
- A Gateway resource exists with HTTPS listener sections that the caller can reference for Grafana and Alertmanager, or the caller sets `listener_set` and the module brings its own listeners (see below).
- `grafana_host` and `alert_manager_host` are the public hostnames served by those HTTPRoutes. Grafana's `server.root_url` and Alertmanager's `externalUrl` follow them, so OAuth redirects, Slack alert links and the Silence button resolve publicly instead of pointing at the in-cluster Service.

## EKS usage

```hcl
module "monitoring" {
  source = "github.com/contiamo/terraform?ref=monitoring/v1.0.0"

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
  source = "github.com/contiamo/terraform?ref=monitoring/v1.0.0"

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

### Own listeners through a ListenerSet

Set `listener_set` when the Gateway has no listener that covers the two hosts, for example the tailnet identity gateway, which takes a ListenerSet per app. The module then creates a ListenerSet `monitoring` in its namespace with one HTTPS listener per host (sections `grafana` and `alertmanager`), and both HTTPRoutes attach to it. cert-manager issues a certificate per host through the given ClusterIssuer. The `*_gateway_parent_ref` variables are ignored and can be left out.

```hcl
  listener_set = {
    gateway_name      = "tailnet-id-gateway"
    gateway_namespace = "tailnet-id-gateway"
    cluster_issuer    = "letsencrypt-production-route53-multi-zone"
  }
  grafana_host       = "grafana.example.com"
  alert_manager_host = "alertmanager.example.com"
```

The issuer must be able to validate both hosts. No external-dns target annotation is set: ExternalDNS falls back to the parent Gateway's target.

### Prometheus storage and retention

Prometheus keeps its data on a persistent volume (`prometheus_storage_size_gb`, default 30 GiB) for `prometheus_retention` (default `30d`), and also stops at 90% of the volume size so the disk cannot fill. The volume uses `prometheus_storage_class`, falling back to `grafana_pvc_storage_class` and then to the cluster default. `prometheus_resources` sets its requests (default 100m CPU, 1Gi memory, no limits).

```hcl
prometheus_storage_size_gb = 60
prometheus_retention       = "60d"
```

Before v1.4.0 the chart kept the data in an emptyDir, and every restart lost the history.

### Loki retention

Loki keeps logs for `loki_retention_period` (default `730d`, two years) and deletes older chunks and index tables from its bucket. `0s` keeps them for ever. The compactor applies retention every `loki_retention_sweep_interval` (default `24h`). Each sweep reads every index table, one per day of history, so sweeping on every 10-minute compaction cycle, as v1.2.0 to v1.4.0 did, costs hundreds of thousands of S3 calls a day.

```hcl
loki_retention_period = "365d"
```

Retention also provides the log deletion API (`/loki/api/v1/delete`).

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
