# Static list of supported Karpenter versions. Each entry must have:
#   * charts/karpenter-<version>.tgz       — Helm chart pulled from
#                                           oci://public.ecr.aws/karpenter/karpenter
#   * charts/karpenter-<version>.tgz.sha256 — OCI manifest digest sidecar
#   * crds/<version>/<crd>.yaml             — four CRDs from
#                                           https://raw.githubusercontent.com/aws/karpenter-provider-aws/v<version>/pkg/apis/crds
#
# To add a new version, run scripts/update-karpenter.sh <version> (or wait
# for the daily update-karpenter workflow to open a PR).
locals {
  supported_versions = [
    "1.12.0",
  ]

  # Karpenter v1 CRDs. Stable across versions on the v1.x line.
  crd_files = toset([
    "karpenter.k8s.aws_ec2nodeclasses",
    "karpenter.sh_nodeclaims",
    "karpenter.sh_nodeoverlays",
    "karpenter.sh_nodepools",
  ])
}
