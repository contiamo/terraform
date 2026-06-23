# eks-external-dns

Deploys [external-dns](https://kubernetes-sigs.github.io/external-dns/) on an EKS
cluster: an IRSA role scoped to specific Route 53 hosted zones, plus the
external-dns Helm release wired to assume it.

This is a purpose-built replacement for `lablabs/eks-external-dns/aws`. That
module is a thin wrapper over a large generic addon framework (Helm + ArgoCD +
OIDC + IRSA + pod-identity); we only ever used the Helm + IRSA + Route 53 slice.
Owning a small module instead removes the framework's deprecated
`managed_policy_arns` output and its non-`_v1` `kubernetes_*` resource blocks,
and drops the `cloudposse/utils` provider dependency.

## What it creates

- `aws_iam_policy` — Route 53 `ChangeResourceRecordSets` scoped to
  `route53_zone_ids`, plus the list/read actions on `*`.
- `aws_iam_role` (+ attachment) — IRSA role trusting the cluster OIDC provider
  for the external-dns ServiceAccount.
- `helm_release` — the external-dns chart, ServiceAccount annotated with the
  role ARN.

## Usage

```hcl
module "external_dns" {
  source = "github.com/contiamo/terraform?ref=eks-external-dns/v1.0.0"

  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks.oidc_provider_arn
  route53_zone_ids        = var.route53_zone_ids

  helm_chart_version           = "1.21.1"
  policy                       = "sync"
  sources                      = ["service", "ingress", "gateway-httproute", "gateway-grpcroute"]
  enable_gateway_listener_sets = true
}
```

## Migrating from `lablabs/eks-external-dns/aws`

The resource addresses change, so migrate the existing role/policy/attachment
and Helm release into this module with `import` blocks (and drop the old module
from state with `removed` / `state rm`) — no destroy/recreate. `role_name`
defaults to the lablabs-generated `external-dns-irsa-external-dns` so the IAM
imports are clean.

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| cluster_oidc_issuer_url | EKS OIDC issuer URL | required |
| oidc_provider_arn | EKS OIDC provider ARN | required |
| route53_zone_ids | Allowed Route 53 hosted zone IDs | required |
| helm_chart_version | external-dns chart version | `"1.21.1"` |
| namespace | Release namespace | `"kube-system"` |
| service_account_name | ServiceAccount name | `"external-dns"` |
| role_name | IRSA role + policy name | `"external-dns-irsa-external-dns"` |
| policy | external-dns sync policy | `"sync"` |
| sources | Watched source types | service, ingress, gateway-httproute, gateway-grpcroute |
| enable_gateway_listener_sets | Add `--gateway-listener-sets` | `true` |
| aws_partition | Partition for zone ARNs | `"aws"` |
| tags | Tags on IAM role/policy | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| irsa_role_arn | ARN of the IRSA role |
| irsa_role_name | Name of the IRSA role |
| irsa_policy_arn | ARN of the Route 53 policy |
| helm_release_name | external-dns Helm release name |
| namespace | Deployment namespace |
