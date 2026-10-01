terraform {
  required_version = ">= 1.3.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

locals {
  namespace = var.create_namespace ? kubernetes_namespace_v1.coder[0].metadata[0].name : var.namespace

  wildcard_enabled = var.wildcard_access_host != null

  # The chart hardcodes the ListenerSet name to "coder"; the HTTPRoute
  # parentRefs below must use the same name.
  listenerset_name = "coder"

  # Secret names cannot contain "*", so the wildcard cert gets a fixed name.
  # cert-manager's ListenerSet controller creates the Certificate from the
  # listener's certificateRefs and the cluster-issuer annotation.
  wildcard_tls_secret_name = "coder-wildcard-tls"

  listenerset_annotations = local.wildcard_enabled ? merge(
    { "cert-manager.io/cluster-issuer" = var.cert_manager_cluster_issuer },
    var.listenerset_annotations
  ) : {}
}

resource "kubernetes_namespace_v1" "coder" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name   = var.namespace
    labels = var.namespace_labels
  }
}

resource "helm_release" "coder" {
  name             = "coder"
  repository       = "https://helm.coder.com/v2"
  chart            = "coder"
  version          = var.chart_version
  namespace        = local.namespace
  create_namespace = false
  max_history      = 3

  values = compact([
    templatefile("${path.module}/assets/helm-values.yaml.tpl", {
      access_host              = var.access_host
      wildcard_access_host     = var.wildcard_access_host
      wildcard_enabled         = local.wildcard_enabled
      wildcard_tls_secret_name = local.wildcard_tls_secret_name
      listenerset_name         = local.listenerset_name
      listenerset_annotations  = local.listenerset_annotations
      gateway                  = var.gateway_parent_ref
      database                 = var.database
      oidc                     = var.oidc
      proxy_trusted_origins    = var.proxy_trusted_origins
      replica_count            = var.replica_count
      resources                = var.resources
      workspace_namespaces     = var.workspace_namespaces
      telemetry_enabled        = var.telemetry_enabled
      extra_env                = var.extra_env
    }),
    var.extra_helm_values,
  ])
}
