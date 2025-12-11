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

# Local variables for naming and listener configuration
locals {
  # EnvoyProxy names - use custom name if provided, otherwise default pattern
  public_envoyproxy_name   = var.public_envoyproxy_name != null ? var.public_envoyproxy_name : "${var.public_gateway_name}-proxy"
  internal_envoyproxy_name = var.internal_envoyproxy_name != null ? var.internal_envoyproxy_name : "${var.internal_gateway_name}-proxy"

  # Listener configurations - use custom listeners if provided, otherwise build from domains
  public_listener_configs = var.public_listeners != null ? var.public_listeners : [
    for idx, domain in var.public_domains : {
      domain = domain
      name   = tostring(idx)
    }
  ]

  internal_listener_configs = var.internal_listeners != null ? var.internal_listeners : [
    for idx, domain in var.internal_domains : {
      domain = domain
      name   = tostring(idx)
    }
  ]

  # Helper function to generate TLS secret name
  # Pattern can include {domain} or {idx} placeholders
  public_tls_secrets = {
    for idx, listener in local.public_listener_configs :
    listener.name => replace(replace(
      "${var.public_gateway_name}${var.public_tls_secret_suffix}",
      "{domain}", replace(replace(listener.domain, "*.", ""), ".", "-")
    ), "{idx}", listener.name)
  }

  internal_tls_secrets = {
    for idx, listener in local.internal_listener_configs :
    listener.name => replace(replace(
      "${var.internal_gateway_name}${var.internal_tls_secret_suffix}",
      "{domain}", replace(replace(listener.domain, "*.", ""), ".", "-")
    ), "{idx}", listener.name)
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
        name      = local.public_envoyproxy_name
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
        name      = local.internal_envoyproxy_name
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
      name      = local.public_envoyproxy_name
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
      name      = local.internal_envoyproxy_name
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
    for listener in local.public_listener_configs : {
      name     = "http-${listener.name}"
      protocol = "HTTP"
      port     = 80
      hostname = listener.domain
      allowedRoutes = {
        namespaces = {
          from = "All"
        }
      }
    }
  ] : []

  public_https_listeners = var.public_gateway_enabled ? [
    for listener in local.public_listener_configs : {
      name     = "https-${listener.name}"
      protocol = "HTTPS"
      port     = 443
      hostname = listener.domain
      tls = {
        mode = "Terminate"
        certificateRefs = [{
          kind = "Secret"
          name = local.public_tls_secrets[listener.name]
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
    for listener in local.internal_listener_configs : {
      name     = "http-${listener.name}"
      protocol = "HTTP"
      port     = 80
      hostname = listener.domain
      allowedRoutes = {
        namespaces = {
          from = "All"
        }
      }
    }
  ] : []

  internal_https_listeners = var.internal_gateway_enabled ? [
    for listener in local.internal_listener_configs : {
      name     = "https-${listener.name}"
      protocol = "HTTPS"
      port     = 443
      hostname = listener.domain
      tls = {
        mode = "Terminate"
        certificateRefs = [{
          kind = "Secret"
          name = local.internal_tls_secrets[listener.name]
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
        for listener in local.public_listener_configs : {
          name        = var.public_gateway_name
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
        for listener in local.internal_listener_configs : {
          name        = var.internal_gateway_name
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
