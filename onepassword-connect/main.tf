terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0"
    }
  }
}

# ----------------------------------------------------------------------------
# 1Password Connect CRDs (onepassword.com/OnePasswordItem)
# ----------------------------------------------------------------------------
# The chart's /crds/ directory is only installed by Helm on first install and
# is NEVER updated on `helm upgrade`. We install it explicitly per chart
# version via server-side apply so that a chart bump that ships an updated
# CRD schema actually reaches the cluster.
#
# Pattern mirrored from envoy-gateway / gateway-api-crds.

resource "terraform_data" "onepassword_crds_version_check" {
  input = var.chart_version

  lifecycle {
    precondition {
      condition     = contains(keys(local.chart_version_to_crds_map), var.chart_version)
      error_message = <<-EOT
        Unsupported chart_version: "${var.chart_version}"

        Supported versions: ${jsonencode(keys(local.chart_version_to_crds_map))}

        To add a new version, run:
          ./onepassword-connect/scripts/update-onepassword-crds.sh <version>

        Or wait for the daily update-onepassword-connect-crds workflow to
        open a PR.
      EOT
    }
  }
}

data "kubectl_file_documents" "onepassword_crds" {
  depends_on = [terraform_data.onepassword_crds_version_check]
  content    = file("${path.module}/crds/onepassword-crd-${var.chart_version}.yaml")
}

resource "kubectl_manifest" "onepassword_crds" {
  for_each          = toset(local.chart_version_to_crds_map[var.chart_version])
  yaml_body         = data.kubectl_file_documents.onepassword_crds.manifests[each.value]
  server_side_apply = true
  force_conflicts   = true
  wait              = true
}

# ----------------------------------------------------------------------------
# Connect server + Operator Helm release
# ----------------------------------------------------------------------------
# The 1password/connect chart is a single umbrella that can deploy:
#   * the Connect server (connect.create)
#   * the Operator      (operator.create)
# individually or together. Ingress is always disabled in favour of the
# Gateway-API-native HTTPRoute below.

locals {
  operator_values = merge(
    {
      create     = var.install_operator
      authMethod = var.operator_auth_method
    },
    var.operator_auth_method == "connect" ? {
      token = { value = var.operator_token }
    } : {},
    var.operator_auth_method == "service-account" ? {
      serviceAccountToken = { value = var.operator_service_account_token }
    } : {},
  )

  connect_values = {
    create             = var.install_connect_server
    credentials_base64 = var.connect_credentials_base64
    ingress = {
      enabled = false
    }
  }

  module_values = {
    connect  = local.connect_values
    operator = local.operator_values
  }
}

resource "helm_release" "connect" {
  depends_on = [kubectl_manifest.onepassword_crds]

  name             = var.release_name
  namespace        = var.namespace
  chart            = "connect"
  repository       = "https://1password.github.io/connect-helm-charts"
  version          = var.chart_version
  create_namespace = true
  skip_crds        = true
  max_history      = 3
  timeout          = 300
  wait             = true

  values = [yamlencode(local.module_values), yamlencode(var.extra_values)]
}

# ----------------------------------------------------------------------------
# Gateway API HTTPRoute (optional)
# ----------------------------------------------------------------------------
# Exposes the Connect server on an existing Gateway when `host` is set. The
# chart's built-in Ingress is disabled above, so this is the only way the
# module exposes Connect externally. Leave `host` null for operator-only
# deployments or in-cluster-only Connect.

resource "kubectl_manifest" "httproute" {
  count      = var.install_connect_server && var.host != null ? 1 : 0
  depends_on = [helm_release.connect]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = var.release_name
      namespace = var.namespace
    }
    spec = {
      parentRefs = [{
        group       = "gateway.networking.k8s.io"
        kind        = "Gateway"
        name        = var.gateway_name
        namespace   = var.gateway_namespace
        sectionName = var.gateway_section_name
      }]
      hostnames = [var.host]
      rules = [{
        matches = [{
          path = {
            type  = "PathPrefix"
            value = "/"
          }
        }]
        backendRefs = [{
          group = ""
          kind  = "Service"
          name  = "onepassword-connect"
          port  = 8080
        }]
      }]
    }
  })
}
