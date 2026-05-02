# Envoy Gateway Terraform Module

Deploys [Envoy Gateway](https://gateway.envoyproxy.io/) on Kubernetes with support for multiple gateways using the Kubernetes Gateway API.

> ## ⚠️ Version Compatibility
>
> This module installs **Envoy Gateway** (the controller) **plus its
> Envoy-Gateway-specific CRDs** (`gateway.envoyproxy.io/*`). Both are pinned
> to `var.chart_version`.
>
> The **upstream Gateway API CRDs** (`gateway.networking.k8s.io/*`) are managed
> by a separate [`gateway-api-crds`](../gateway-api-crds/) module and pinned
> independently.
>
> **You are responsible for keeping these versions compatible.** Always check
> the Envoy Gateway compatibility matrix:
> <https://gateway.envoyproxy.io/news/releases/matrix/>
>
> It is OK to run with newer Gateway API CRDs than Envoy Gateway officially
> supports — Envoy Gateway will simply ignore unknown resource types until
> you upgrade the controller. We deliberately run Gateway API v1.5.1 with
> Envoy Gateway v1.7.x today, awaiting Envoy Gateway v1.8.0 (which adds
> standard `ListenerSet` support from Gateway API v1.5).
>
> ### Adding a new Envoy Gateway version
>
> The chart_version variable only accepts versions that have a corresponding
> CRDs file under `crds/envoy-crds-<version>.yaml`. The daily
> `update-envoy-gateway-crds` GitHub Actions workflow adds new versions
> automatically when Envoy Gateway publishes a release. To add one manually:
>
> ```bash
> ./envoy-gateway/scripts/update-envoy-crds.sh v1.8.0
> ```

## Usage

### Basic Example (Single Public Gateway)

```hcl
module "envoy_gateway" {
  source = "github.com/contiamo/terraform?ref=envoy-gateway/v1.0.0"

  gateways = [{
    name = "envoy-public"
    listeners = [
      { domain = "*.example.com", name = "0" }
    ]
    lb_annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
    }
  }]
}
```

### Multiple Gateways (Public + Internal)

```hcl
module "envoy_gateway" {
  source = "github.com/contiamo/terraform?ref=envoy-gateway/v1.0.0"


  chart_version               = "v1.7.2"
  replicas                    = 2
  cert_manager_cluster_issuer = "letsencrypt-production"

  gateways = [
    {
      name            = "envoy-public"
      envoyproxy_name = "envoy-proxy-public"  # Custom name for migration
      listeners = [
        { domain = "*.ctmo.io", name = "ctmo" },
        { domain = "*.contiamo.com", name = "contiamo" }
      ]
      tls_secret_suffix = "-{idx}-tls-auto-generated"
      lb_annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
        "service.beta.kubernetes.io/aws-load-balancer-type"            = "nlb"
        "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
      }
    },
    {
      name            = "envoy-tailscale"
      envoyproxy_name = "envoy-proxy-tailscale"
      listeners = [
        { domain = "*.ctmo.io", name = "ctmo" },
        { domain = "*.contiamo.com", name = "contiamo" }
      ]
      tls_secret_suffix = "-{idx}-tls-auto-generated"
      lb_annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internal"
      }
    }
  ]
}
```

### OTC Example

```hcl
module "envoy_gateway" {
  source = "github.com/contiamo/terraform?ref=envoy-gateway/v1.0.0"

  cert_manager_cluster_issuer = "letsencrypt-production-dns01"

  gateways = [{
    name = "envoy-public"
    listeners = [
      { domain = "*.gw.otc.example.com", name = "0" }
    ]
    lb_annotations = {
      "kubernetes.io/elb.class" = "union"
      "kubernetes.io/elb.autocreate" = jsonencode({
        type                 = "public"
        bandwidth_name       = "envoy-gateway-public-bandwidth"
        bandwidth_chargemode = "traffic"
        bandwidth_size       = 300
        bandwidth_sharetype  = "PER"
        eip_type             = "5_bgp"
      })
    }
  }]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| chart_version | Envoy Gateway Helm chart version | `string` | `"v1.7.2"` | no |
| namespace | Kubernetes namespace | `string` | `"envoy-gateway-system"` | no |
| replicas | Number of Envoy proxy replicas | `number` | `2` | no |
| cert_manager_cluster_issuer | Default cert-manager ClusterIssuer | `string` | `"letsencrypt-production-route53"` | no |
| enable_grafana_dashboards | Install the upstream Envoy Gateway Grafana dashboards as a sidecar-discovered ConfigMap | `bool` | `true` | no |
| enable_metrics_scraping | Install ServiceMonitor (control plane) + PodMonitor (data plane) for Prometheus | `bool` | `true` | no |
| monitoring_namespace | Namespace where kube-prometheus-stack runs | `string` | `"monitoring"` | no |
| dashboard_label | Label key the Grafana sidecar watches | `string` | `"grafana_dashboard"` | no |
| dashboard_label_value | Value paired with `dashboard_label` | `string` | `"1"` | no |
| service_monitor_release_label | Label key the Prometheus CR's monitor selector requires | `string` | `"release"` | no |
| service_monitor_release_value | Value paired with `service_monitor_release_label` | `string` | `"monitoring-stack"` | no |
| gateways | List of gateway configurations | `list(object)` | n/a | yes |

### Gateway Object

| Field | Description | Type | Default |
|-------|-------------|------|---------|
| name | Gateway name | `string` | required |
| enabled | Whether to create this gateway | `bool` | `true` |
| envoyproxy_name | Custom EnvoyProxy resource name | `string` | `"{name}-proxy"` |
| listeners | List of listener configs | `list(object)` | required |
| lb_annotations | LoadBalancer annotations | `map(string)` | required |
| gateway_annotations | Extra annotations on the Gateway resource (merged with the cert-manager annotation) | `map(string)` | `{}` |
| tls_secret_suffix | TLS secret suffix pattern | `string` | `"-tls-{idx}"` |
| cert_manager_issuer | Override default issuer | `string` | null |

### Listener Object

| Field | Description | Default |
|-------|-------------|---------|
| domain | Domain pattern (e.g., `"*.example.com"`) | required |
| name | Listener name suffix (creates `http-{name}` and `https-{name}`) | required |
| tls_secret_name | Override the auto-generated TLS Secret name. Use when reusing a Secret managed elsewhere (e.g. by an existing nginx Ingress's cert-manager Certificate) so cutover does not require a fresh ACME issuance. If unset, the Secret name is derived from `tls_secret_suffix` on the parent Gateway. | derived |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Namespace where Envoy Gateway is deployed |
| gateways | Map of gateway configurations with service names |
| gateway_names | List of enabled gateway names |
| service_names | Map of gateway names to K8s service names |

## Observability

By default the module installs:

- **5 Grafana dashboards** (vendored under `dashboards/`, pinned to `chart_version`) as a ConfigMap labelled for the kube-prometheus-stack Grafana sidecar. Dashboards land under `Dashboards/General` (or whichever folder your sidecar is configured to drop them in) named `Envoy Proxy Global`, `Envoy Clusters`, `Envoy Gateway Global`, `Resources Monitor`, and `Global Ratelimit`.
- **A ServiceMonitor** (`envoy-gateway`) scraping the controller's `metrics` port (19001 / `/metrics`).
- **A PodMonitor** (`envoy-proxy`) scraping every Envoy proxy pod the controller spawns (port `metrics`, path `/stats/prometheus`).

Disable either with:

```hcl
module "envoy_gateway" {
  # …
  enable_grafana_dashboards = false   # skip the ConfigMap
  enable_metrics_scraping   = false   # skip ServiceMonitor + PodMonitor
}
```

If your kube-prometheus-stack release name isn't `monitoring-stack`, override `service_monitor_release_value` so the Prometheus CR's selector picks the monitors up.

### Refreshing the dashboards

When bumping `chart_version`, refresh the vendored JSON next to the CRD bump:

```bash
./envoy-gateway/scripts/update-envoy-crds.sh v1.8.0
./envoy-gateway/scripts/update-envoy-dashboards.sh v1.8.0
```

## Creating HTTPRoutes

Route traffic to your services:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app
  namespace: my-namespace
spec:
  parentRefs:
    - name: envoy-public
      namespace: envoy-gateway-system
      sectionName: https-ctmo  # or https-0 for numeric names
  hostnames:
    - "my-app.ctmo.io"
  rules:
    - backendRefs:
        - name: my-app-service
          port: 80
```
