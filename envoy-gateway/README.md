# Envoy Gateway Terraform Module

This module deploys [Envoy Gateway](https://gateway.envoyproxy.io/) on Kubernetes with support for both public and internal (Tailscale) gateways using the Kubernetes Gateway API.

## Overview

This module creates and manages:

- Envoy Gateway Helm release
- GatewayClass resources for public and/or internal traffic
- EnvoyProxy configurations with LoadBalancer services
- Gateway resources with HTTP/HTTPS listeners
- HTTPRoute resources for automatic HTTPS redirect

## Requirements

| Name      | Version  |
| --------- | -------- |
| terraform | >= 1.3.0 |
| helm      | >= 2.0   |
| kubectl   | >= 1.14  |

## Usage

### Basic Example (Public Gateway Only)

```hcl
module "envoy_gateway" {
  # contiamo-release-please-bump-start
  source = "github.com/contiamo/terraform//envoy-gateway?ref=v0.9.0"
  # contiamo-release-please-bump-end

  public_gateway_enabled  = true
  internal_gateway_enabled = false

  public_domains = ["*.gw.example.com"]
  public_lb_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
  }

  # Required but unused when internal gateway is disabled
  internal_domains        = []
  internal_lb_annotations = {}
}
```

### Complete Example (Public + Internal Gateways)

```hcl
module "envoy_gateway" {
  # contiamo-release-please-bump-start
  source = "github.com/contiamo/terraform//envoy-gateway?ref=v0.9.0"
  # contiamo-release-please-bump-end

  chart_version = "v1.5.5"
  namespace     = "envoy-gateway-system"
  replicas      = 2

  # Public Gateway
  public_gateway_enabled = true
  public_gateway_name    = "envoy-public"
  public_domains         = ["*.gw.example.com"]
  public_lb_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
  }

  # Internal Gateway (Tailscale)
  internal_gateway_enabled = true
  internal_gateway_name    = "envoy-tailscale"
  internal_domains         = ["*.ts.example.com"]
  internal_lb_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internal"
    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
  }

  cert_manager_cluster_issuer = "letsencrypt-production-route53"
}
```

### OTC Example (Public Only)

```hcl
module "envoy_gateway" {
  # contiamo-release-please-bump-start
  source = "github.com/contiamo/terraform//envoy-gateway?ref=v0.9.0"
  # contiamo-release-please-bump-end

  public_gateway_enabled   = true
  internal_gateway_enabled = false

  public_domains = ["*.gw.otc.example.com"]
  public_lb_annotations = {
    "kubernetes.io/elb.class"             = "union"
    "kubernetes.io/elb.autocreate"        = jsonencode({
      type                  = "public"
      bandwidth_name        = "envoy-public-bandwidth"
      bandwidth_chargemode  = "traffic"
      bandwidth_size        = 300
      bandwidth_sharetype   = "PER"
      eip_type              = "5_bgp"
    })
  }

  internal_domains        = []
  internal_lb_annotations = {}

  cert_manager_cluster_issuer = "letsencrypt-production-dns01"
}
```

## Inputs

| Name                        | Description                                                | Type           | Default                          | Required |
| --------------------------- | ---------------------------------------------------------- | -------------- | -------------------------------- | :------: |
| chart_version               | Envoy Gateway Helm chart version                           | `string`       | `"v1.5.5"`                       |    no    |
| namespace                   | Kubernetes namespace for Envoy Gateway                     | `string`       | `"envoy-gateway-system"`         |    no    |
| replicas                    | Number of Envoy proxy replicas                             | `number`       | `2`                              |    no    |
| public_gateway_enabled      | Enable public gateway                                      | `bool`         | `true`                           |    no    |
| public_gateway_name         | Name for the public gateway resources                      | `string`       | `"envoy-public"`                 |    no    |
| public_domains              | List of domains for the public gateway                     | `list(string)` | n/a                              |   yes    |
| public_lb_annotations       | Annotations for the public load balancer service           | `map(string)`  | n/a                              |   yes    |
| internal_gateway_enabled    | Enable internal/tailscale gateway                          | `bool`         | `true`                           |    no    |
| internal_gateway_name       | Name for the internal gateway resources                    | `string`       | `"envoy-tailscale"`              |    no    |
| internal_domains            | List of domains for the internal gateway                   | `list(string)` | n/a                              |   yes    |
| internal_lb_annotations     | Annotations for the internal load balancer service         | `map(string)`  | n/a                              |   yes    |
| cert_manager_cluster_issuer | The cert-manager ClusterIssuer name for TLS certificates   | `string`       | `"letsencrypt-production-route53"` |    no    |

## Outputs

| Name                   | Description                                              |
| ---------------------- | -------------------------------------------------------- |
| namespace              | The namespace where Envoy Gateway is deployed            |
| public_gateway_name    | The name of the public gateway                           |
| internal_gateway_name  | The name of the internal gateway                         |
| public_gateway_class   | The name of the public GatewayClass                      |
| internal_gateway_class | The name of the internal GatewayClass                    |
| public_service_name    | The Kubernetes service name for the public gateway       |
| internal_service_name  | The Kubernetes service name for the internal gateway     |

## Creating HTTPRoutes

After deploying the gateway, create HTTPRoutes in your application namespaces to route traffic:

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
      sectionName: https-0
  hostnames:
    - "my-app.gw.example.com"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-app-service
          port: 80
```

## Notes

- The module automatically creates HTTPS redirect routes for all HTTP listeners
- TLS certificates are managed by cert-manager using the specified ClusterIssuer
- Gateway service names follow the pattern: `envoy-{namespace}-{gateway-name}`
- When using internal gateways with Tailscale, ensure your Tailscale operator is configured

## License

This module is maintained by Contiamo.
