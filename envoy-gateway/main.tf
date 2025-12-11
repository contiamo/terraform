terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

# Build a map of enabled gateways for use with for_each
locals {
  enabled_gateways = {
    for gw in var.gateways : gw.name => gw if gw.enabled
  }

  # Generate TLS secret names for each gateway's listeners
  gateway_tls_secrets = {
    for gw_name, gw in local.enabled_gateways : gw_name => {
      for listener in gw.listeners : listener.name => replace(
        "${gw.name}${coalesce(gw.tls_secret_suffix, "-tls-{idx}")}",
        "{idx}", listener.name
      )
    }
  }
}

# Deploy Envoy Gateway Helm chart (single instance)
resource "helm_release" "envoy_gateway" {
  name             = "eg"
  repository       = "oci://registry-1.docker.io/envoyproxy"
  version          = var.chart_version
  chart            = "gateway-helm"
  namespace        = var.namespace
  create_namespace = true
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
      annotations = {
        "cert-manager.io/cluster-issuer" = coalesce(each.value.cert_manager_issuer, var.cert_manager_cluster_issuer)
      }
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
