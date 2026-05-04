# Gateway API CRDs Terraform Module

Installs the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) CRDs using server-side apply. The CRDs are committed from the official upstream `standard-install.yaml` release artefacts.

## Usage

```hcl
module "gateway_api_crds" {
  source = "github.com/contiamo/terraform?ref=gateway-api-crds/v1.0.0"

  crd_version = "v1.5.1"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| crd_version | Gateway API CRD version to install | `string` | `"v1.5.1"` | no |

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
