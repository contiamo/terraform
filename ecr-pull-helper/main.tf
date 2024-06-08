resource "kubernetes_namespace_v1" "ecr_helper_namespace" {
  metadata {
    name = var.ecr_helper_namespace
    annotations = {
      "purpose" = "This namesopace is used to run the ecr-registry-helper cronjob. The cronjob keeps the ecr-registry-secret to date."
    }
  }
}

resource "kubernetes_secret_v1" "ecr_registry_helper_secret" {
  metadata {
    name      = "ecr-helper-creds"
    namespace = kubernetes_namespace_v1.ecr_helper_namespace.metadata[0].name
  }

  data = {
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
  }
}


resource "kubernetes_service_account_v1" "ecr_helper" {
  metadata {
    name      = var.ecr_helper_svc_account_name
    namespace = kubernetes_namespace_v1.ecr_helper_namespace.metadata[0].name
  }
}

resource "kubernetes_cluster_role_v1" "full_access_to_secrets" {
  metadata {
    name = "ecr-helper-full-access-to-secrets"
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["${var.ecr_registry_secret_name}"]
    verbs          = ["delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["list"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "full_access_to_secrets_role_binding" {
  metadata {
    name = "ecr-helper-full-access-to-secrets"
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.ecr_helper_svc_account_name
    namespace = var.ecr_helper_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.full_access_to_secrets.metadata[0].name
  }
}

resource "kubernetes_cron_job_v1" "ecr_registry_helper" {
  metadata {
    name      = "ecr-helper"
    namespace = kubernetes_namespace_v1.ecr_helper_namespace.metadata[0].name
  }

  spec {
    concurrency_policy            = "Forbid"
    schedule                      = "0 */10 * * *"
    suspend                       = false
    failed_jobs_history_limit     = 3
    successful_jobs_history_limit = 3
    job_template {
      metadata {}
      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 10
        template {
          metadata {}
          spec {
            service_account_name = kubernetes_service_account_v1.ecr_helper.metadata[0].name
            container {
              name              = "ecr-registry-helper"
              image             = "odaniait/aws-kubectl:latest"
              image_pull_policy = "IfNotPresent"

              env_from {
                secret_ref {
                  name = kubernetes_secret_v1.ecr_registry_helper_secret.metadata[0].name
                }
              }

              command = [
                "/bin/sh",
                "-c",
                templatefile("${path.module}/assets/ecr-helper-script.sh.tpl", {
                  AWS_REGION         = var.aws_region,
                  AWS_ACCOUNT        = data.aws_caller_identity.current.account_id,
                  DOCKER_SECRET_NAME = var.ecr_registry_secret_name
                })
              ]
            }
            restart_policy = "Never"
          }
        }
      }
    }
  }
}