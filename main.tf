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

# Build a map of enabled gateways for use with for_each
locals {
  enabled_gateways = {
    for gw in var.gateways : gw.name => gw if gw.enabled
  }

  # Resolve TLS secret names for each gateway's listeners. A listener may
  # override `tls_secret_name` to reference a Secret managed elsewhere
  # (e.g. an existing nginx Ingress's cert-manager Certificate that we
  # don't want to re-issue during a cutover); otherwise the name is
  # derived from `tls_secret_suffix`.
  gateway_tls_secrets = {
    for gw_name, gw in local.enabled_gateways : gw_name => {
      for listener in gw.listeners : listener.name => coalesce(
        listener.tls_secret_name,
        replace(
          "${gw.name}${coalesce(gw.tls_secret_suffix, "-tls-{idx}")}",
          "{idx}", listener.name,
        ),
      )
    }
  }
}

# ----------------------------------------------------------------------------
# Envoy Gateway CRDs (gateway.envoyproxy.io/*)
# ----------------------------------------------------------------------------
# We install Envoy Gateway-specific CRDs from a per-version YAML file rendered
# from gateway-crds-helm.
#
# The main gateway-helm chart (below) uses skip_crds = true so we MUST install
# these CRDs separately or the controller will have nothing to watch.
#
# To add a new chart version, run scripts/update-envoy-crds.sh (or wait for
# the daily update-envoy-gateway-crds workflow to open a PR).
#
# The multi-doc YAML is parsed in pure HCL — `split` separates documents,
# `yamldecode` parses each one, and `for_each` keys are derived from
# `<kind>/<metadata.name>` at plan time. This sidesteps the kubectl provider's
# `data.kubectl_file_documents` deferred-read behaviour, which was causing
# every consumer's plan to mark each `kubectl_manifest` as "update in-place"
# (yaml_body `(known after apply)`) on every run.

# Validate that the chart_version has a corresponding CRDs file. Produces a
# clear error at plan time if someone uses an unsupported version.
resource "terraform_data" "envoy_gateway_crds_version_check" {
  input = var.chart_version

  lifecycle {
    precondition {
      condition     = fileexists("${path.module}/crds/envoy-crds-${var.chart_version}.yaml")
      error_message = <<-EOT
        Unsupported chart_version: "${var.chart_version}"

        No CRDs file found at:
          crds/envoy-crds-${var.chart_version}.yaml

        To add a new version, run:
          ./envoy-gateway/scripts/update-envoy-crds.sh <version>

        Or wait for the daily update-envoy-gateway-crds workflow to open a PR.
      EOT
    }
  }
}

locals {
  envoy_crd_docs = [
    for doc in split("\n---\n", file("${path.module}/crds/envoy-crds-${var.chart_version}.yaml")) :
    yamldecode(doc) if can(yamldecode(doc)) && try(yamldecode(doc).kind, null) != null
  ]
  envoy_crd_map = {
    for d in local.envoy_crd_docs : "${d.kind}/${d.metadata.name}" => d
  }
}

resource "kubectl_manifest" "envoy_gateway_crds" {
  for_each = local.envoy_crd_map

  yaml_body         = yamlencode(each.value)
  server_side_apply = true
  force_conflicts   = true
  wait              = true

  depends_on = [terraform_data.envoy_gateway_crds_version_check]
}

# Deploy Envoy Gateway Helm chart.
# Gateway API CRDs are managed externally (gateway-api-crds module).
# Envoy Gateway CRDs are managed by kubectl_manifest.envoy_gateway_crds above.
resource "helm_release" "envoy_gateway" {
  depends_on = [kubectl_manifest.envoy_gateway_crds]

  name             = "eg"
  repository       = "oci://registry-1.docker.io/envoyproxy"
  version          = var.chart_version
  chart            = "gateway-helm"
  namespace        = var.namespace
  create_namespace = true
  skip_crds        = true
  max_history      = 3
  timeout          = 600
}

# GatewayClass for each gateway
resource "kubectl_manifest" "gatewayclass" {
  for_each   = local.enabled_gateways
  depends_on = [helm_release.envoy_gateway]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = each.key
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = coalesce(each.value.envoyproxy_name, "${each.key}-proxy")
        namespace = var.namespace
      }
    }
  })
}

# EnvoyProxy for each gateway
resource "kubectl_manifest" "envoyproxy" {
  for_each   = local.enabled_gateways
  depends_on = [helm_release.envoy_gateway]

  yaml_body = yamlencode({
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata = {
      name      = coalesce(each.value.envoyproxy_name, "${each.key}-proxy")
      namespace = var.namespace
    }
    spec = {
      provider = {
        type = "Kubernetes"
        kubernetes = {
          envoyDeployment = {
            replicas = var.replicas
          }
          envoyService = {
            type        = "LoadBalancer"
            annotations = each.value.lb_annotations
          }
        }
      }
    }
  })
}

# Gateway for each gateway configuration
resource "kubectl_manifest" "gateway" {
  for_each = local.enabled_gateways
  depends_on = [
    kubectl_manifest.gatewayclass,
    kubectl_manifest.envoyproxy
  ]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = each.key
      namespace = var.namespace
      annotations = merge(
        {
          "cert-manager.io/cluster-issuer" = coalesce(each.value.cert_manager_issuer, var.cert_manager_cluster_issuer)
        },
        each.value.gateway_annotations,
      )
    }
    spec = {
      gatewayClassName = each.key
      listeners = concat(
        # HTTP listeners
        [
          for listener in each.value.listeners : {
            name     = "http-${listener.name}"
            protocol = "HTTP"
            port     = 80
            hostname = listener.domain
            allowedRoutes = {
              namespaces = { from = "All" }
            }
          }
        ],
        # HTTPS listeners
        [
          for listener in each.value.listeners : {
            name     = "https-${listener.name}"
            protocol = "HTTPS"
            port     = 443
            hostname = listener.domain
            tls = {
              mode = "Terminate"
              certificateRefs = [{
                kind = "Secret"
                name = local.gateway_tls_secrets[each.key][listener.name]
              }]
            }
            allowedRoutes = {
              namespaces = { from = "All" }
            }
          }
        ]
      )
    }
  })
}

# HTTPRoute for HTTPS redirect for each gateway
resource "kubectl_manifest" "httproute_redirect" {
  for_each   = local.enabled_gateways
  depends_on = [kubectl_manifest.gateway]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "${each.key}-https-redirect"
      namespace = var.namespace
    }
    spec = {
      parentRefs = [
        for listener in each.value.listeners : {
          name        = each.key
          sectionName = "http-${listener.name}"
        }
      ]
      rules = [{
        filters = [{
          type = "RequestRedirect"
          requestRedirect = {
            scheme     = "https"
            statusCode = 301
          }
        }]
      }]
    }
  })
}
