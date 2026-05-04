# Karpenter Terraform Module

Deploys [Karpenter](https://karpenter.sh/) — the just-in-time Kubernetes node autoscaler — together with its v1 CRDs, on an EKS cluster.

> ## ⚠️ Why this module exists
>
> Karpenter publishes its Helm chart **only** to `oci://public.ecr.aws/karpenter`. The current `terraform-provider-helm` v3 (helm SDK 3.18+, oras-go v2) issues `POST` requests to AWS Public ECR's `/token/` endpoint, which only accepts `GET` per the Docker Registry token-auth spec. The result is intermittent **`405 Method Not Allowed`** errors during `tofu plan`/`apply` — affecting a different OCI helm_release on each run, until the apply succeeds by luck.
>
> Refs:
> * [helm/helm#30970](https://github.com/helm/helm/issues/30970) — open
> * [hashicorp/terraform-provider-helm#1731](https://github.com/hashicorp/terraform-provider-helm/issues/1731) — open
>
> This module sidesteps the bug by:
>
> * Vendoring the chart `.tgz` and CRDs **per Karpenter version** under `charts/` and `crds/<version>/`.
> * Pointing `helm_release.controller` at a local file path so the helm provider never reaches for OCI.
> * Installing CRDs via `kubectl_manifest` (server-side apply) instead of a separate `helm_release.karpenter-crd`.
>
> ### Adding a new Karpenter version
>
> The daily `update-karpenter` GitHub Actions workflow opens a PR automatically when AWS publishes a new Karpenter release. To add one manually:
>
> ```bash
> ./karpenter/scripts/update-karpenter.sh 1.13.0
> ```
>
> Each version commit includes:
> * `charts/karpenter-<version>.tgz` — the helm chart pulled from OCI
> * `charts/karpenter-<version>.tgz.sha256` — OCI manifest digest for audit
> * `crds/<version>/*.yaml` — the four v1 CRDs at the matching git tag
>
> Reviewers should diff the `.tgz` digest against what `helm pull` produces, and skim the CRD YAMLs for schema-breaking changes.

## Usage

```hcl
module "karpenter_chart" {
  source = "github.com/contiamo/terraform?ref=karpenter/v1.0.0"

  chart_version = "1.12.0"

  cluster_name             = module.eks.cluster_name
  cluster_endpoint         = module.eks.cluster_endpoint
  interruption_queue       = module.karpenter.queue_name
  service_account_role_arn = module.karpenter_irsa.arn
}
```

The module installs the Karpenter controller and its four v1 CRDs (`EC2NodeClass`, `NodeClaim`, `NodeOverlay`, `NodePool`).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `chart_version` | Karpenter version. Must be in `locals.supported_versions`. Named `chart_version` (not `version`) because Terraform reserves `version` as a module-block meta-argument. | `string` | `"1.12.0"` | no |
| `namespace` | Kubernetes namespace for the controller. | `string` | `"karpenter"` | no |
| `release_name` | Helm release name. | `string` | `"karpenter"` | no |
| `cluster_name` | EKS cluster name (`settings.clusterName`). | `string` | n/a | **yes** |
| `cluster_endpoint` | EKS API endpoint (`settings.clusterEndpoint`). | `string` | n/a | **yes** |
| `interruption_queue` | SQS queue name for spot interruption notices. Typically `module.karpenter.queue_name` from `terraform-aws-modules/eks/aws/modules/karpenter`. | `string` | n/a | **yes** |
| `service_account_role_arn` | IRSA role ARN for the controller's ServiceAccount. | `string` | n/a | **yes** |
| `replicas` | Controller replica count. | `number` | `2` | no |
| `tolerations` | Pod tolerations. Defaults to a Fargate-compute toleration so the controller can land before any data-plane node exists. | `list(object)` | (Fargate) | no |
| `webhook` | Conversion webhook config. Required by Karpenter v1 CRDs. | `object` | `{ enabled = true, port = 8443 }` | no |
| `extra_values` | Additional Helm values merged into the rendered values. | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `namespace` | Namespace the controller is deployed in. |
| `release_name` | Helm release name. |
| `version` | Karpenter version installed. |

## Migration from in-workspace `helm_release`

If you currently install Karpenter directly with two `helm_release` blocks (`karpenter` and `karpenter-crd`) in your workspace, switch to this module without uninstalling karpenter:

```hcl
# Drop helm_release.karpenter_crd from state without destroying CRDs.
# kubectl_manifest will take over via SSA, harmless overlap on labels.
removed {
  from = helm_release.karpenter_crd
  lifecycle {
    destroy = false
  }
}

# Keep the controller release alive — the resource address moves into the
# module. Same name, namespace, chart name, version: no real change at
# the cluster level, just a state-address shift.
moved {
  from = helm_release.karpenter
  to   = module.karpenter_chart.helm_release.controller
}

module "karpenter_chart" {
  source = "github.com/contiamo/terraform?ref=karpenter/v1.0.0"
  # …inputs as above
}
```

Plan should show:
* `helm_release.karpenter_crd` — removed from state (no destroy, no apply-time call to helm).
* `module.karpenter_chart.helm_release.controller` — in-place update (chart attribute changes from OCI to local path; helm sees same name+version, no-op patch).
* `module.karpenter_chart.kubectl_manifest.crd[*]` — 4 creates (SSA over existing CRDs, no recreation).
* 0 destroys.

After apply, the orphaned `karpenter-crd` Helm release record can be cleaned up with `helm delete --keep-history karpenter-crd -n karpenter` if you want the cluster's helm secrets tidy. Optional — the orphan record has no functional effect.
