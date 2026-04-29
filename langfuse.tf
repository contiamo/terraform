# Namespace for Langfuse deployment
resource "kubernetes_namespace_v1" "langfuse" {
  metadata {
    name = var.langfuse_namespace
  }
}

# Generate random credentials for Langfuse components
resource "random_password" "admin_password" {
  length  = 32
  special = false
}

resource "random_password" "nextauth_secret" {
  length  = 32
  special = false
}

resource "random_password" "salt" {
  length  = 32
  special = false
}

resource "random_password" "postgres_password" {
  length  = 32
  special = false
}

resource "random_password" "clickhouse_password" {
  length  = 32
  special = false
}

resource "random_password" "valkey_password" {
  length  = 32
  special = false
}

resource "random_password" "minio_root_password" {
  length  = 32
  special = false
}

resource "random_password" "langfuse_public_key" {
  length  = 32
  special = false
}

resource "random_password" "langfuse_secret_key" {
  length  = 32
  special = false
}

# Create Kubernetes secret with all credentials
resource "kubernetes_secret_v1" "langfuse_admin" {
  depends_on = [kubernetes_namespace_v1.langfuse]

  metadata {
    name      = "langfuse-admin"
    namespace = var.langfuse_namespace
  }

  data = {
    admin-email                      = var.admin_email
    admin-password                   = random_password.admin_password.result
    nextauth-secret                  = random_password.nextauth_secret.result
    salt                             = random_password.salt.result
    postgres-password                = random_password.postgres_password.result
    clickhouse-password              = random_password.clickhouse_password.result
    valkey-password                  = random_password.valkey_password.result
    minio-root-user                  = "minio"
    minio-root-password              = random_password.minio_root_password.result
    LANGFUSE_INIT_PROJECT_PUBLIC_KEY = "lf_pk_${random_password.langfuse_public_key.result}"
    LANGFUSE_INIT_PROJECT_SECRET_KEY = "lf_sk_${random_password.langfuse_secret_key.result}"
  }

  type = "Opaque"
}

# Deploy Langfuse via Helm
# TLS certificate automatically created by cert-manager via Ingress annotation
resource "helm_release" "langfuse" {
  depends_on = [
    kubernetes_secret_v1.langfuse_admin
  ]

  name             = "langfuse"
  repository       = "https://langfuse.github.io/langfuse-k8s"
  chart            = "langfuse"
  version          = var.chart_version
  namespace        = var.langfuse_namespace
  create_namespace = false
  max_history      = 3

  values = [
    templatefile("${path.module}/assets/helm-values.yaml", {
      ORG_ID                       = var.org_id
      ORG_NAME                     = var.org_name
      PROJECT_ID                   = var.project_id
      PROJECT_NAME                 = var.project_name
      LANGFUSE_HOST                = var.langfuse_host
      CLICKHOUSE_VOLUME_SIZE       = var.clickhouse_volume_size
      S3_VOLUME_SIZE               = var.s3_volume_size
      INGRESS_CLASS_NAME           = var.ingress_class_name
      CERT_MANAGER_CLUSTER_ISSUER  = var.cert_manager_cluster_issuer
    })
  ]
}
