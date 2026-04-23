# Gateway API CRDs Terraform Module

Installs the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) CRDs using server-side apply. The CRDs are committed from the official upstream `standard-install.yaml` release artefacts.

## Usage

```hcl
module "gateway_api_crds" {
  # contiamo-release-please-bump-start
  source = "github.com/contiamo/terraform//gateway-api-crds?ref=v0.19.0"
  # contiamo-release-please-bump-end

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

1. Download the standard install YAML:
   ```bash
   curl -Lo crds/vX.Y.Z-standard-install.yaml \
     https://github.com/kubernetes-sigs/gateway-api/releases/download/vX.Y.Z/standard-install.yaml
   ```

2. Get the manifest keys by running a targeted plan:
   ```bash
   tofu plan -target=data.kubectl_file_documents.gateway_api_crds
   ```

3. Add the version entry to `locals.tf` with the manifest keys from step 2.

4. Update the `crd_version` default in `variables.tf`.
