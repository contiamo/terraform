# Coder Terraform Module

Deploys [Coder](https://coder.com), self-hosted remote development environments, via the official `coder-v2/coder` Helm chart.

The module manages the control plane only (coderd + its built-in provisioner). Workspace templates are configured inside Coder afterwards.

- Postgres is external: an existing database such as AWS RDS, referenced through a Kubernetes Secret the caller creates. An in-cluster mode backed by [CloudNativePG](https://cloudnative-pg.io/) is planned; the `database.mode` field is reserved for it.
- Exposure is Gateway API only. The control-plane hostname rides on the parent Gateway's shared wildcard listener. The optional wildcard hostname for subdomain-based workspace apps gets its own `ListenerSet` and cert-manager certificate, rendered by the chart.
- TLS terminates at the Gateway; the Coder Service is `ClusterIP`.

## Requirements

| Name       | Version  |
| ---------- | -------- |
| terraform  | >= 1.3.0 |
| helm       | >= 2.0   |
| kubernetes | >= 2.0   |

## Prerequisites

- Gateway API CRDs v1.5+ (standard-channel `ListenerSet`) and a Gateway controller that honours them (Envoy Gateway v1.8+, see the [envoy-gateway module](../envoy-gateway)). The parent Gateway must allow listeners from other namespaces (`allowedListeners.namespaces.from: All`, the envoy-gateway module default since v1.4.0).
- cert-manager with Gateway API support and `--enable-gateway-api-listenerset`, plus a DNS-01 `ClusterIssuer` for the wildcard hostname.
- external-dns watching HTTPRoutes, if DNS records should be created automatically.
- A reachable Postgres 13+ database and a Secret in the Coder namespace holding its connection URL.

## Usage

```terraform
# The namespace is created here so the database Secret can exist before Coder starts.
resource "kubernetes_namespace_v1" "coder" {
  metadata {
    name = "coder"
  }
}

resource "kubernetes_secret_v1" "coder_db_url" {
  metadata {
    name      = "coder-db-url"
    namespace = kubernetes_namespace_v1.coder.metadata[0].name
  }
  data = {
    url = "postgres://coder:${var.coder_db_password}@my-rds.eu-central-1.rds.amazonaws.com:5432/coder?sslmode=require"
  }
}

module "coder" {
  # To reference as a private repo use "git@github.com:contiamo/terraform.git?ref=coder/v1.0.0"
  source = "github.com/contiamo/terraform?ref=coder/v1.0.0"

  namespace        = kubernetes_namespace_v1.coder.metadata[0].name
  create_namespace = false

  access_host          = "coder.example.com"
  wildcard_access_host = "*.coder.example.com"

  gateway_parent_ref = {
    name         = "envoy-public"
    namespace    = "envoy-gateway-system"
    section_name = "https-example"
  }
  cert_manager_cluster_issuer = "letsencrypt-production-route53"

  database = {
    secret_name = kubernetes_secret_v1.coder_db_url.metadata[0].name
    # secret_key defaults to "url"
  }

  depends_on = [kubernetes_secret_v1.coder_db_url]
}
```

### With OIDC login

```terraform
module "coder" {
  # ...

  oidc = {
    issuer_url                = "https://accounts.google.com"
    client_id                 = "1234.apps.googleusercontent.com"
    client_secret_secret_name = "coder-oidc"   # Secret with key "client-secret"
    email_domains             = ["example.com"]
    sign_in_text              = "Sign in with Google"
    # disable_password_auth = true  # only after an OIDC user is admin
  }
}
```

### On a cluster whose Gateway pins external-dns to one address

Copy the parent Gateway's annotation onto the ListenerSet, nothing more:

```terraform
  listenerset_annotations = {
    "external-dns.kubernetes.io/target" = "203.0.113.10"
  }
```

## How the wildcard hostname is served

`*.coder.example.com` is not covered by the Gateway's `*.example.com` certificate. Adding a second certificate to the shared Gateway would trigger `OverlappingCertificates` and disable HTTP/2 for every listener on that port, so the chart creates a `ListenerSet` named `coder` in the Coder namespace instead:

- `https` listener on 443 terminating TLS with Secret `coder-wildcard-tls`. cert-manager creates and owns the `Certificate` from the `cert-manager.io/cluster-issuer` annotation.
- `http` listener on 80 carrying a 301 redirect `HTTPRoute`, because the Gateway's own redirect route is bound to the Gateway's listeners and does not see this hostname.
- `allowedRoutes` is omitted, so only HTTPRoutes in the Coder namespace can attach (Gateway API default `namespaces.from: Same`).

The single `coder` HTTPRoute lists both hostnames and both parents. Gateway API intersects hostnames per parent, so `coder.example.com` binds to the Gateway listener and `*.coder.example.com` to the ListenerSet.

Coder itself never touches DNS or certificates. A workspace app at `code-server--main--mywork--alice.coder.example.com` is routed by coderd from the `Host` header to the agent tunnel of that workspace.

## Variables

| Name                        | Description                                                                                            | Type           | Default                                   | Required |
| --------------------------- | ------------------------------------------------------------------------------------------------------ | -------------- | ----------------------------------------- | :------: |
| access_host                 | Control-plane hostname; becomes `CODER_ACCESS_URL` and the HTTPRoute hostname                          | `string`       | n/a                                       |   yes    |
| gateway_parent_ref          | Gateway parentRef `{name, namespace, section_name}` for the control-plane hostname                     | `object`       | n/a                                       |   yes    |
| database                    | `{mode = "external", secret_name, secret_key = "url"}`; Secret holding the Postgres URL                | `object`       | n/a                                       |   yes    |
| wildcard_access_host        | `*.`-prefixed hostname for subdomain workspace apps; enables the ListenerSet                            | `string`       | `null`                                    |    no    |
| cert_manager_cluster_issuer | DNS-01 ClusterIssuer for the wildcard certificate; required with `wildcard_access_host`                | `string`       | `null`                                    |    no    |
| listenerset_annotations     | Extra ListenerSet annotations (e.g. external-dns target pinning)                                       | `map(string)`  | `{}`                                      |    no    |
| oidc                        | OIDC login settings, see above; `null` keeps password login only                                       | `object`       | `null`                                    |    no    |
| proxy_trusted_origins       | CIDRs of the proxy pods; enables `X-Forwarded-For` trust                                               | `list(string)` | `[]`                                      |    no    |
| namespace                   | Namespace for the control plane and, by default, workspaces                                            | `string`       | `"coder"`                                 |    no    |
| create_namespace            | Create the namespace; `false` when the caller manages it                                               | `bool`         | `true`                                    |    no    |
| namespace_labels            | Labels on the created namespace                                                                        | `map(string)`  | `{}`                                      |    no    |
| chart_version               | coder-v2/coder chart version (equals the app version)                                                  | `string`       | `"2.37.3"`                                |    no    |
| replica_count               | coderd replicas                                                                                        | `number`       | `1`                                       |    no    |
| resources                   | coderd container resources                                                                             | `object`       | 500m/1Gi requests, 2000m/4Gi limits       |    no    |
| workspace_namespaces        | Extra namespaces where the Coder ServiceAccount may create workspaces                                  | `list(string)` | `[]`                                      |    no    |
| telemetry_enabled           | `CODER_TELEMETRY_ENABLE`                                                                               | `bool`         | `false`                                   |    no    |
| extra_env                   | Additional `{name, value}` env vars for coderd                                                         | `list(object)` | `[]`                                      |    no    |
| extra_helm_values           | YAML string merged last over the generated values                                                      | `string`       | `""`                                      |    no    |

## Outputs

| Name                 | Description                                                      |
| -------------------- | ---------------------------------------------------------------- |
| namespace            | Namespace where Coder is deployed                                |
| url                  | `https://<access_host>`                                          |
| wildcard_access_url  | Wildcard hostname, `null` when disabled                          |
| internal_url         | In-cluster Service URL (plain HTTP)                              |
| service_account_name | ServiceAccount used by coderd and the built-in provisioner       |
| listenerset_name     | ListenerSet name, `null` when disabled                           |
| chart_version        | Deployed chart version                                           |

## Post-deployment

1. Open `https://<access_host>`. The first visit creates the initial admin account (password login).
2. Add a Kubernetes workspace template (Coder ships a starter: Templates, Starter templates, Kubernetes). Point `namespace` at the Coder namespace or one listed in `workspace_namespaces`.
3. If OIDC is configured, sign in through it once, promote that user to owner, then consider `disable_password_auth = true`.

## Follow-ups

- In-cluster Postgres via CloudNativePG as `database.mode = "cloudnative-pg"`.
- External provisioner daemons (`coder.provisionerDaemon.pskSecretName`) if workspaces move to other clusters.
