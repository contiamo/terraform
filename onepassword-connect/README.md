# 1Password Connect Terraform Module

Deploys the [1Password Connect Helm chart](https://github.com/1Password/connect-helm-charts) — the **Connect server**, the **Kubernetes Operator**, or both — together with its `OnePasswordItem` CRD, and (optionally) exposes the Connect server on an existing Gateway API `Gateway` via an `HTTPRoute`.

> ## ⚠️ Why this module exists
>
> The [`1password/connect`](https://github.com/1Password/connect-helm-charts) chart ships its single `onepassworditems.onepassword.com` CRD under the chart's `/crds/` directory. Helm installs `/crds/` files **once**, on first install, and never on subsequent `helm upgrade` runs. That means a chart bump that updates the CRD schema would silently leave the old schema in place.
>
> This module solves that the same way [`envoy-gateway`](../envoy-gateway/) and [`gateway-api-crds`](../gateway-api-crds/) do:
>
> * The CRD YAML is committed **per chart version** under `crds/onepassword-crd-<version>.yaml`
> * `kubectl_manifest` applies it server-side, with `force_conflicts = true`
> * `skip_crds = true` on the `helm_release` so Helm leaves the CRD alone
> * A `terraform_data` precondition rejects any `chart_version` without a committed CRD file, so you get a clear error at plan time
>
> ### Adding a new chart version
>
> The daily `update-onepassword-connect-crds` GitHub Actions workflow opens a PR automatically when 1Password publishes a new chart release. To add one manually:
>
> ```bash
> ./onepassword-connect/scripts/update-onepassword-crds.sh 2.4.2
> ```

## Usage

### Connect server + Operator (typical Contiamo EKS setup)

```hcl
module "onepassword_connect" {
  source = "github.com/contiamo/terraform//onepassword-connect?ref=onepassword-connect/v1.0.0"

  chart_version = "2.4.1"
  namespace     = "1password"

  install_connect_server = true
  install_operator       = true

  connect_credentials_base64 = module.onepassword_connect_credentials_base64.value
  operator_token             = data.onepassword_item.operator_token.credential

  # Expose the Connect server on the public gateway so e.g. GitHub Actions
  # runners can reach it. Omit these fields for in-cluster-only Connect.
  host                 = "1passconnect.eks.example.com"
  gateway_name         = "envoy-public"
  gateway_namespace    = "envoy-gateway-system"
  gateway_section_name = "https-example"
}
```

### Operator-only (no Connect server, uses a Service Account token)

Use this when the cluster should read secrets from 1Password without running a Connect server locally — the Operator talks directly to 1Password's cloud.

```hcl
module "onepassword_operator" {
  source = "github.com/contiamo/terraform//onepassword-connect?ref=onepassword-connect/v1.0.0"

  chart_version = "2.4.1"
  namespace     = "1password"

  install_connect_server = false
  install_operator       = true

  operator_auth_method           = "service-account"
  operator_service_account_token = data.onepassword_item.sa_token.credential
}
```

## Inputs

| Name                            | Description                                                                     | Type     | Default            | Required |
| ------------------------------- | ------------------------------------------------------------------------------- | -------- | ------------------ | :------: |
| chart_version                   | 1Password Connect Helm chart version                                            | `string` | `"2.4.1"`          |    no    |
| namespace                       | Kubernetes namespace                                                            | `string` | `"1password"`      |    no    |
| release_name                    | Helm release name                                                               | `string` | `"connect-server"` |    no    |
| install_connect_server          | Deploy the Connect server                                                       | `bool`   | `true`             |    no    |
| install_operator                | Deploy the Operator                                                             | `bool`   | `true`             |    no    |
| operator_auth_method            | `connect` or `service-account`                                                  | `string` | `"connect"`        |    no    |
| connect_credentials_base64      | Base64-encoded `1password-credentials.json` (required when Connect is enabled)  | `string` | `null`             | cond.\*  |
| operator_token                  | Connect API token used by the Operator when `auth_method = connect`             | `string` | `null`             | cond.\*  |
| operator_service_account_token  | Service Account token used by the Operator when `auth_method = service-account` | `string` | `null`             | cond.\*  |
| host                            | External hostname for the Connect server (null = no HTTPRoute)                  | `string` | `null`             |    no    |
| gateway_name                    | Name of the `Gateway` the HTTPRoute attaches to                                 | `string` | `null`             | cond.\*  |
| gateway_namespace               | Namespace of the `Gateway`                                                      | `string` | `null`             | cond.\*  |
| gateway_section_name            | sectionName of the `Gateway` listener                                           | `string` | `null`             | cond.\*  |
| extra_values                    | Additional Helm values, deep-merged on top                                      | `any`    | `{}`               |    no    |

\* Conditional: required only when the corresponding feature is enabled (see variable descriptions).

## Outputs

| Name                   | Description                                          |
| ---------------------- | ---------------------------------------------------- |
| namespace              | Namespace where Connect / Operator is deployed       |
| release_name           | Helm release name                                    |
| connect_service_name   | Kubernetes Service name (`onepassword-connect`)      |
| connect_http_url       | In-cluster base URL for the Connect API              |
| host                   | External hostname for the Connect server, if any     |

## Referencing secrets via `OnePasswordItem`

With the Operator deployed, sync a 1Password item into a Kubernetes Secret:

```yaml
apiVersion: onepassword.com/v1
kind: OnePasswordItem
metadata:
  name: my-app-db
  namespace: my-app
spec:
  itemPath: vaults/<vault-id>/items/<item-id>
```

The Operator will create/update a `Secret` named `my-app-db` in the `my-app` namespace with the item's fields as keys.

## References

* 1Password Connect chart: <https://github.com/1Password/connect-helm-charts>
* 1Password Operator docs: <https://developer.1password.com/docs/connect/connect-operator/>
* Pattern origin (envoy-gateway CRD management): see [`../envoy-gateway/`](../envoy-gateway/)
