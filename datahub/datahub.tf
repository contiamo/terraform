# Create the namespace:
resource "kubernetes_namespace_v1" "datahub_namespoace" {
  metadata {
    annotations = {
      name = "purpose"
      value = "datahub"
    }

    labels = {
      "com.contiamo/datahub-tracking" = "true"
    }

    name = var.datahub_namespace
  }
}
resource "random_string" "password" {
  length  = 12
  special = false
  upper   = true
}

resource "random_string" "admin_password" {
  length  = 12
  special = false
  upper   = true
}

resource "kubernetes_secret" "mysql_secret" {
  depends_on = [resource.random_string.password,resource.kubernetes_namespace_v1.datahub_namespoace]
  metadata {
    name = "mysql-secrets"
    namespace = var.datahub_namespace
  }
  data = {
    mysql-root-password = "${random_string.password.result}"
  }
}

resource "kubernetes_secret" "neo4j_secret" {
  depends_on = [resource.random_string.password,resource.kubernetes_namespace_v1.datahub_namespoace]
  metadata {
    name      = "neo4j-secrets"
    namespace = var.datahub_namespace
  }
  data = {
    neo4j-password = "${random_string.password.result}"
  }
}

resource "kubernetes_secret" "datahub_default_users" {
  depends_on = [resource.random_string.admin_password,resource.kubernetes_namespace_v1.datahub_namespoace]
  metadata {
    name      = "datahub-default-users"
    namespace = var.datahub_namespace
  }
  data = {
    "user.props" = "datahub:${random_string.admin_password.result}"
  }
}

resource "helm_release" "datahub_prerequisites" {
  depends_on  = [resource.kubernetes_secret.mysql_secret,resource.kubernetes_secret.neo4j_secret]
  provider    = helm
  name        = "prerequisites"
  repository  = "https://helm.datahubproject.io/"
  chart       = "datahub-prerequisites"
  namespace   = var.datahub_namespace
  max_history = 3
  create_namespace = true
  wait             = true
  reset_values     = true
}
# Install Datahub
resource "helm_release" "datahub" {
  depends_on  = [resource.helm_release.datahub_prerequisites]
  provider    = helm
  name        = "datahub"
  repository  = "https://helm.datahubproject.io/"
  chart       = "datahub"
  namespace   = var.datahub_namespace
  max_history = 3
  create_namespace = true
    values = [
        templatefile("${path.module}/helm-values.tpl", { UI_INGRESS_HOST = var.ui_ingress_host, API_INGRESS_HOST = var.api_ingress_host, INGRESS_CLASS  = var.ingress_class })
    ]
}
