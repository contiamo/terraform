# Static list of supported Karpenter versions. Each entry must have:
#   * charts/karpenter-<version>.tgz       — Helm chart pulled from
#                                           oci://public.ecr.aws/karpenter/karpenter
#   * charts/karpenter-<version>.tgz.sha256 — OCI manifest digest sidecar
#   * crds/<version>/<crd>.yaml             — every CRD the chart ships in its
#                                           crds/ directory (extracted from the .tgz)
#
# To add a new version, run scripts/update-karpenter.sh <version> (or wait
# for the daily update-karpenter workflow to open a PR).
locals {
  supported_versions = [
    "1.15.1",
    "1.14.1",
    "1.13.0",
    "1.12.1",
    "1.12.0",
  ]

  # CRDs vendored for the selected version, keyed by file name without
  # `.yaml`. Derived from the directory rather than a static list because the
  # set grows between versions: 1.14 added
  # autoscaling.x-k8s.io_capacitybuffers. Helm only installs a chart's crds/
  # on the first install, never on upgrade, so any CRD missing here would
  # never reach an existing cluster.
  crd_files = toset([
    for f in fileset("${path.module}/crds/${var.chart_version}", "*.yaml") : trimsuffix(f, ".yaml")
  ])
}
