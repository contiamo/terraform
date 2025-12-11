# Envoy Gateway Terraform Module

Deploys [Envoy Gateway](https://gateway.envoyproxy.io/) on Kubernetes with support for multiple gateways using the Kubernetes Gateway API.

## Usage

### Basic Example (Single Public Gateway)

```hcl
module "envoy_gateway" {
  source = "github.com/contiamo/terraform//envoy-gateway?ref=v0.10.0"

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
  source = "github.com/contiamo/terraform//envoy-gateway?ref=v0.10.0"

  chart_version               = "v1.5.5"
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
  source = "github.com/contiamo/terraform//envoy-gateway?ref=v0.10.0"

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
| chart_version | Envoy Gateway Helm chart version | `string` | `"v1.5.5"` | no |
| namespace | Kubernetes namespace | `string` | `"envoy-gateway-system"` | no |
| replicas | Number of Envoy proxy replicas | `number` | `2` | no |
| cert_manager_cluster_issuer | Default cert-manager ClusterIssuer | `string` | `"letsencrypt-production-route53"` | no |
| gateways | List of gateway configurations | `list(object)` | n/a | yes |

### Gateway Object

| Field | Description | Type | Default |
|-------|-------------|------|---------|
| name | Gateway name | `string` | required |
| enabled | Whether to create this gateway | `bool` | `true` |
| envoyproxy_name | Custom EnvoyProxy resource name | `string` | `"{name}-proxy"` |
| listeners | List of listener configs | `list(object)` | required |
| lb_annotations | LoadBalancer annotations | `map(string)` | required |
| tls_secret_suffix | TLS secret suffix pattern | `string` | `"-tls-{idx}"` |
| cert_manager_issuer | Override default issuer | `string` | null |

### Listener Object

| Field | Description |
|-------|-------------|
| domain | Domain pattern (e.g., `"*.example.com"`) |
| name | Listener name suffix (creates `http-{name}` and `https-{name}`) |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Namespace where Envoy Gateway is deployed |
| gateways | Map of gateway configurations with service names |
| gateway_names | List of enabled gateway names |
| service_names | Map of gateway names to K8s service names |

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
