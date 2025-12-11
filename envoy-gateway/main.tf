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

# Deploy Envoy Gateway Helm chart
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

# GatewayClass for public traffic
resource "kubectl_manifest" "gatewayclass_public" {
  count      = var.public_gateway_enabled ? 1 : 0
  depends_on = [helm_release.envoy_gateway]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = var.public_gateway_name
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = "${var.public_gateway_name}-proxy"
        namespace = var.namespace
      }
    }
  })
}

# GatewayClass for internal traffic
resource "kubectl_manifest" "gatewayclass_internal" {
  count      = var.internal_gateway_enabled ? 1 : 0
  depends_on = [helm_release.envoy_gateway]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = var.internal_gateway_name
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = "${var.internal_gateway_name}-proxy"
        namespace = var.namespace
      }
    }
  })
}

# EnvoyProxy for public traffic
resource "kubectl_manifest" "envoyproxy_public" {
  count      = var.public_gateway_enabled ? 1 : 0
  depends_on = [helm_release.envoy_gateway]

  yaml_body = yamlencode({
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata = {
      name      = "${var.public_gateway_name}-proxy"
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
            annotations = var.public_lb_annotations
          }
        }
      }
    }
  })
}

# EnvoyProxy for internal traffic
resource "kubectl_manifest" "envoyproxy_internal" {
  count      = var.internal_gateway_enabled ? 1 : 0
  depends_on = [helm_release.envoy_gateway]

  yaml_body = yamlencode({
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata = {
      name      = "${var.internal_gateway_name}-proxy"
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
            annotations = var.internal_lb_annotations
          }
        }
      }
    }
  })
}

# Build listeners for public gateway
locals {
  public_http_listeners = var.public_gateway_enabled ? [
    for idx, domain in var.public_domains : {
      name     = "http-${idx}"
      protocol = "HTTP"
      port     = 80
      hostname = domain
      allowedRoutes = {
        namespaces = {
          from = "All"
        }
      }
    }
  ] : []

  public_https_listeners = var.public_gateway_enabled ? [
    for idx, domain in var.public_domains : {
      name     = "https-${idx}"
      protocol = "HTTPS"
      port     = 443
      hostname = domain
      tls = {
        mode = "Terminate"
        certificateRefs = [{
          kind = "Secret"
          name = "${var.public_gateway_name}-tls-${idx}"
        }]
      }
      allowedRoutes = {
        namespaces = {
          from = "All"
        }
      }
    }
  ] : []

  internal_http_listeners = var.internal_gateway_enabled ? [
    for idx, domain in var.internal_domains : {
      name     = "http-${idx}"
      protocol = "HTTP"
      port     = 80
      hostname = domain
      allowedRoutes = {
        namespaces = {
          from = "All"
        }
      }
    }
  ] : []

  internal_https_listeners = var.internal_gateway_enabled ? [
    for idx, domain in var.internal_domains : {
      name     = "https-${idx}"
      protocol = "HTTPS"
      port     = 443
      hostname = domain
      tls = {
        mode = "Terminate"
        certificateRefs = [{
          kind = "Secret"
          name = "${var.internal_gateway_name}-tls-${idx}"
        }]
      }
      allowedRoutes = {
        namespaces = {
          from = "All"
        }
      }
    }
  ] : []
}

# Gateway for public traffic
resource "kubectl_manifest" "gateway_public" {
  count = var.public_gateway_enabled ? 1 : 0
  depends_on = [
    kubectl_manifest.gatewayclass_public,
    kubectl_manifest.envoyproxy_public
  ]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = var.public_gateway_name
      namespace = var.namespace
      annotations = {
        "cert-manager.io/cluster-issuer" = var.cert_manager_cluster_issuer
      }
    }
    spec = {
      gatewayClassName = var.public_gateway_name
      listeners        = concat(local.public_http_listeners, local.public_https_listeners)
    }
  })
}

# Gateway for internal traffic
resource "kubectl_manifest" "gateway_internal" {
  count = var.internal_gateway_enabled ? 1 : 0
  depends_on = [
    kubectl_manifest.gatewayclass_internal,
    kubectl_manifest.envoyproxy_internal
  ]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = var.internal_gateway_name
      namespace = var.namespace
      annotations = {
        "cert-manager.io/cluster-issuer" = var.cert_manager_cluster_issuer
      }
    }
    spec = {
      gatewayClassName = var.internal_gateway_name
      listeners        = concat(local.internal_http_listeners, local.internal_https_listeners)
    }
  })
}

# HTTPRoute for public HTTPS redirect
resource "kubectl_manifest" "httproute_public_redirect" {
  count      = var.public_gateway_enabled ? 1 : 0
  depends_on = [kubectl_manifest.gateway_public]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "${var.public_gateway_name}-https-redirect"
      namespace = var.namespace
    }
    spec = {
      parentRefs = [
        for idx, _ in var.public_domains : {
          name        = var.public_gateway_name
          sectionName = "http-${idx}"
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

# HTTPRoute for internal HTTPS redirect
resource "kubectl_manifest" "httproute_internal_redirect" {
  count      = var.internal_gateway_enabled ? 1 : 0
  depends_on = [kubectl_manifest.gateway_internal]

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "${var.internal_gateway_name}-https-redirect"
      namespace = var.namespace
    }
    spec = {
      parentRefs = [
        for idx, _ in var.internal_domains : {
          name        = var.internal_gateway_name
          sectionName = "http-${idx}"
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
