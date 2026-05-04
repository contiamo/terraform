# ----------------------------------------------------------------------------
# Karpenter — controller + CRDs from local artefacts (no OCI fetch at apply)
# ----------------------------------------------------------------------------
# Karpenter publishes its chart **only** to oci://public.ecr.aws/karpenter.
# A bug in helm SDK 3.18 / oras-go v2 (helm/helm#30970, terraform-provider-helm#1731)
# forces a POST against AWS Public ECR's `/token/` endpoint, which only
# accepts GET → 405 Method Not Allowed. The bug is intermittent per apply
# and effectively unfixable from the consumer side.
#
# This module sidesteps it by:
#   * Vendoring the chart `.tgz` and the four v1 CRD YAMLs per supported
#     version under `charts/` and `crds/<version>/`.
#   * Pointing `helm_release.controller` at the local `.tgz` path so the
#     helm provider never reaches for OCI.
#   * Installing CRDs via `kubectl_manifest` (server-side apply) rather than
#     a separate `helm_release.karpenter_crd`, halving the attack surface
#     and removing the need to keep the karpenter-crd Helm release alive.
#
# Trade-offs:
#   * Chart bumps require regenerating the artefacts. The daily
#     update-karpenter workflow does this automatically; the
#     scripts/update-karpenter.sh script does it manually.
#   * Cosign verification of OCI artefacts is not enforced here. The OCI
#     manifest digest is captured in `charts/karpenter-<version>.tgz.sha256`
#     so reviewers can verify the committed `.tgz` against what is published.

resource "terraform_data" "version_check" {
  input = var.chart_version

  lifecycle {
    precondition {
      condition     = contains(local.supported_versions, var.chart_version)
      error_message = <<-EOT
        Unsupported version: "${var.chart_version}"

        Supported versions: ${jsonencode(local.supported_versions)}

        To add a new version, run:
          ./karpenter/scripts/update-karpenter.sh <new-version>

        Or wait for the daily update-karpenter workflow to open a PR.
      EOT
    }
  }
}

# ----------------------------------------------------------------------------
# CRDs — server-side apply, one resource per CRD file. Plan-time-known
# for_each keys (no data.kubectl_file_documents drift).
# ----------------------------------------------------------------------------

resource "kubectl_manifest" "crd" {
  for_each = local.crd_files

  yaml_body         = file("${path.module}/crds/${var.chart_version}/${each.key}.yaml")
  server_side_apply = true
  force_conflicts   = true
  wait              = true

  depends_on = [terraform_data.version_check]
}

# ----------------------------------------------------------------------------
# Controller Helm release. `chart` is the local path to the `.tgz` —
# helm provider reads it directly without touching any registry.
# ----------------------------------------------------------------------------

locals {
  controller_values = merge(
    {
      replicas    = var.replicas
      tolerations = var.tolerations
      settings = {
        clusterName       = var.cluster_name
        clusterEndpoint   = var.cluster_endpoint
        interruptionQueue = var.interruption_queue
      }
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = var.service_account_role_arn
        }
      }
      webhook = var.webhook
    },
    var.extra_values,
  )
}

resource "helm_release" "controller" {
  depends_on = [kubectl_manifest.crd]

  name             = var.release_name
  namespace        = var.namespace
  create_namespace = true

  chart   = "${path.module}/charts/karpenter-${var.chart_version}.tgz"
  version = var.chart_version

  values = [yamlencode(local.controller_values)]
}
