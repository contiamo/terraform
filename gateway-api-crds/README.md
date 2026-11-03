# Gateway API CRDs Terraform Module

Installs the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) CRDs using server-side apply. The CRDs are committed from the official upstream `standard-install.yaml` release artefacts.

## Usage

```hcl
module "gateway_api_crds" {
  source = "github.com/contiamo/terraform?ref=gateway-api-crds/v1.0.0"

  crd_version = "v1.6.2"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| crd_version | Gateway API CRD version to install | `string` | `"v1.6.2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| crd_version | The installed Gateway API CRD version |

## Adding a new Gateway API version

The daily `update-gateway-api-crds` GitHub Actions workflow opens a PR
automatically when a new Gateway API version is released. To add one
manually:

```bash
./gateway-api-crds/scripts/update-crds.sh v1.6.0
```

The script downloads the standard-install YAML and bumps the default in
`variables.tf` and the example in this README. No manual key tracking is
needed — the module parses the YAML at plan time and derives `for_each`
keys from `<kind>/<metadata.name>`.

## Envoy Gateway compatibility (check before merging or bumping)

Envoy Gateway is the Gateway API controller on every cluster that uses this
module. Each Envoy Gateway release is compiled and tested against exactly one
Gateway API version: the bold "Gateway API version" column in the
[compatibility matrix](https://gateway.envoyproxy.io/news/releases/matrix/),
which is also the `sigs.k8s.io/gateway-api` pin in Envoy Gateway's `go.mod`.

Rules:

- Do not merge a new CRD minor (v1.N) until an Envoy Gateway release is built
  against it.
- Do not move a cluster to a new CRD minor until that cluster runs such an
  Envoy Gateway release. The `envoy-gateway` module and this one are bumped
  separately, so check both pins.
- Rolling back is not a plain revert. From v1.7.0 the bundle installs the
  `safe-upgrades.gateway.networking.k8s.io` ValidatingAdmissionPolicy, which
  rejects any CRD bundle older than the installed minor. Going back means
  deleting that policy first.

The `update-gateway-api-crds` workflow checks the latest stable Envoy Gateway
release and opens the PR as a draft, with a warning, when the new minor is not
supported yet. It does not reopen a version whose PR was closed.
