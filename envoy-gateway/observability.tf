# ----------------------------------------------------------------------------
# Grafana dashboards (kube-prometheus-stack sidecar pickup)
#
# Vendored from envoyproxy/gateway charts/gateway-addons-helm/dashboards at
# the chart_version pin. Refresh with scripts/update-envoy-dashboards.sh on
# chart bumps.
# ----------------------------------------------------------------------------
locals {
  dashboard_files = var.enable_grafana_dashboards ? fileset(path.module, "dashboards/*.json") : []
}

resource "kubectl_manifest" "grafana_dashboards" {
  count = var.enable_grafana_dashboards ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "envoy-gateway-grafana-dashboards"
      namespace = var.monitoring_namespace
      labels = {
        (var.dashboard_label) = var.dashboard_label_value
      }
    }
    data = {
      for f in local.dashboard_files : basename(f) => file("${path.module}/${f}")
    }
  })
}

# ----------------------------------------------------------------------------
# ServiceMonitor — Envoy Gateway control-plane metrics
#
# Scrapes the `envoy-gateway` Service in var.namespace on its `metrics` port
# (19001, /metrics). Selector matches the labels the gateway-helm chart puts
# on the controller Service.
# ----------------------------------------------------------------------------
resource "kubectl_manifest" "envoy_gateway_servicemonitor" {
  count      = var.enable_metrics_scraping ? 1 : 0
  depends_on = [helm_release.envoy_gateway]

  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "envoy-gateway"
      namespace = var.monitoring_namespace
      labels = {
        (var.service_monitor_release_label) = var.service_monitor_release_value
      }
    }
    spec = {
      namespaceSelector = {
        matchNames = [var.namespace]
      }
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"     = "gateway-helm"
          "app.kubernetes.io/instance" = "eg"
        }
      }
      endpoints = [{
        port     = "metrics"
        path     = "/metrics"
        interval = "30s"
      }]
    }
  })
}

# ----------------------------------------------------------------------------
# PodMonitor — Envoy proxy data-plane metrics
#
# The EnvoyProxy CRD has telemetry.metrics.prometheus enabled by default in
# v1.7.x. Pods spawned by the controller carry well-known
# gateway.envoyproxy.io/* labels and expose `metrics` on 19001
# (/stats/prometheus).
# ----------------------------------------------------------------------------
resource "kubectl_manifest" "envoy_proxy_podmonitor" {
  count      = var.enable_metrics_scraping ? 1 : 0
  depends_on = [helm_release.envoy_gateway]

  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"
    metadata = {
      name      = "envoy-proxy"
      namespace = var.monitoring_namespace
      labels = {
        (var.service_monitor_release_label) = var.service_monitor_release_value
      }
    }
    spec = {
      namespaceSelector = {
        matchNames = [var.namespace]
      }
      selector = {
        matchLabels = {
          "app.kubernetes.io/managed-by" = "envoy-gateway"
          "app.kubernetes.io/component"  = "proxy"
        }
      }
      podMetricsEndpoints = [{
        port     = "metrics"
        path     = "/stats/prometheus"
        interval = "30s"
      }]
    }
  })
}
