# C reate a local variable called auth_secret_name:
locals {
  auth_secret_name = "tailscale-auth"
}
resource "kubernetes_namespace_v1" "tailscale" {
  metadata {
    name = var.k8s_namespace
  }
}

resource "kubernetes_role_v1" "tailscale" {
  metadata {
    name = "tailscale"
    namespace = var.k8s_namespace
  }
  rule {
    api_groups = [""]
    resources = ["secrets"]
    verbs = ["create"]
  }
  rule {
    api_groups = [""]
    resources = ["secrets"]
    resource_names = ["${local.auth_secret_name}"]
    verbs = ["get", "update"]
  }
}
# Create a service account:
resource "kubernetes_service_account_v1" "tailscale" {
  # automount_service_account_token = false
  metadata {
    name = "tailscale"
    namespace = var.k8s_namespace
  }
}

resource "kubernetes_role_binding_v1" "tailscale" {
  metadata {
    name = "tailscale"
    namespace = var.k8s_namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = kubernetes_role_v1.tailscale.metadata[0].name
  }
  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account_v1.tailscale.metadata[0].name
    namespace = var.k8s_namespace
  }
}
resource "kubernetes_service_v1" "tailscale-subnet-router" {
  wait_for_load_balancer = false
  metadata {
    name = "tailscale-subnet-router"
    namespace = var.k8s_namespace
  }
  spec {
    cluster_ip = "None"
    internal_traffic_policy = "Cluster"
    ip_families = ["IPv4"]
    ip_family_policy = "SingleStack"
    session_affinity = "None"
    type = "ClusterIP"
    selector = {
      "app" = "tailscale"
    }
  }
}

resource "kubernetes_secret_v1" "tailscale_auth" {
  # Only create this resource is the value of the vcariable create_tailscale_auth_key_secret is set to "true":
  count = var.create_tailscale_auth_key_secret ? 1 : 0
  metadata {
    name = local.auth_secret_name
    namespace = var.k8s_namespace
  }
  data = {
    TS_AUTH_KEY = var.tailscale_auth_key
  }
}

resource "kubernetes_stateful_set_v1" "tailscale-subnet-router" {
  metadata {
    name = "tailscale-subnet-router"
    namespace = var.k8s_namespace
    labels = {
      "app" = "tailscale"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "tailscale"
      }
    }
    service_name = kubernetes_service_v1.tailscale-subnet-router.metadata[0].name
    template {
      metadata {
        labels = {
          "app" = "tailscale"
        }
      }
      spec {
        # automount_service_account_token = false
        enable_service_links = false
        service_account_name = kubernetes_service_account_v1.tailscale.metadata[0].name
        container {
          name = "tailscale"
          image_pull_policy = "IfNotPresent"
          image = "${var.image_name}:${var.image_tag}"
          env {
            name = "TS_AUTH_KEY"

            value_from {
                secret_key_ref {
                  key      = "TS_AUTH_KEY"
                  name     = local.auth_secret_name
                  optional = false
                }
              }
          }
          env {
            name  = "TS_KUBE_SECRET"
            value = "tailscale-auth"
          }
          env {
            name  = "TS_USERSPACE"
            value = "true"
          }
          env {
            name  = "TS_ROUTES"
            value = "${var.k8s_cluster_service_cidr},${var.k8s_cluster_pod_cidr}"
          }
          security_context {
            allow_privilege_escalation = false
            privileged                 = false
            read_only_root_filesystem  = false
            run_as_group               = "1000"
            run_as_non_root            = false
            run_as_user                = "1000"
          }
        }
      }
    }
  }
}