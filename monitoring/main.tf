locals {
  loki_svc_account_name           = "loki"
  is_eks                          = var.target_cluster == "eks"
  loki_values_template            = local.is_eks ? "${path.module}/assets/helm-values-loki.tpl" : "${path.module}/assets/helm-values-loki-non-eks.tpl"
  loki_role_arn                   = local.is_eks ? module.loki_service_account_role[0].arn : ""
  web_endpoint_monitoring_webhook = var.alert_manager_slack_webhook_url_web_endpoint_monitoring != "" ? var.alert_manager_slack_webhook_url_web_endpoint_monitoring : var.alert_manager_slack_webhook_url
}

# Prep. namespace:
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = var.target_namespace
  }
}
# Create Loki storage bucket:
resource "aws_s3_bucket" "loki_storage" {
  bucket = var.loki_storage_bucket_name
  tags   = var.aws_tags
}

# Grant Loki access to the new bucket via a dedicated role (EKS only — non-EKS
# clusters use static AWS credentials passed through the Helm values).
resource "aws_iam_policy" "loki_storage_policy" {
  count       = local.is_eks ? 1 : 0
  name        = "loki-svc-account-policy"
  description = "Policy for Loki storage bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.loki_storage.arn,
        "${aws_s3_bucket.loki_storage.arn}/*", ]
      },
    ]
  })
  tags = var.aws_tags
}

module "loki_service_account_role" {
  count   = local.is_eks ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.1"
  name    = "loki-svc-account-role"
  policies = {
    bucket = aws_iam_policy.loki_storage_policy[0].arn,
  }
  oidc_providers = {
    one = {
      provider_arn = var.oidc_provider_arn
      namespace_service_accounts = [
        "${kubernetes_namespace_v1.monitoring.metadata[0].name}:${local.loki_svc_account_name}"
      ]
    }
  }
}
# Get current region:
data "aws_region" "current" {}
# Create Loki Helm release:
resource "helm_release" "loki" {
  depends_on = [
    kubernetes_namespace_v1.monitoring,
    aws_s3_bucket.loki_storage,
    module.loki_service_account_role,
  ]
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = var.loki_version
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  values = [
    templatefile(local.loki_values_template,
      {
        LOKI_BUCKET_AWS_REGION                = data.aws_region.current.id,
        LOKI_STORAGE_BUCKET_NAME              = aws_s3_bucket.loki_storage.id,
        LOKI_STORAGE_BUCKET_SECRET_ACCESS_KEY = var.loki_storage_bucket_secret_access_key,
        LOKI_STORAGE_BUCKET_ACCESS_KEY_ID     = var.loki_storage_bucket_access_key_id,
        LOKI_STORAGE_CLASS_NAME               = var.loki_storage_class_name,
        LOKI_SVC_ACCOUNT_NAME                 = local.loki_svc_account_name,
        LOKI_SVC_ACCOUNT_IAM_ROLE_ARN         = local.loki_role_arn,
      }
    )
  ]
}
# Prepare Loki datasource conmfigmap that will be picked up by Grafana:
resource "kubernetes_config_map_v1" "loki_datasource" {
  metadata {
    name      = "loki-grafana-datasource"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    labels = {
      "grafana_datasource" = "1"
    }
  }
  data = {
    "datasource.yaml" = <<-EOT
      apiVersion: 1
      datasources:
      - name: Loki
        type: loki
        uid: loki
        url: http://loki-gateway.${kubernetes_namespace_v1.monitoring.metadata[0].name}.svc.cluster.local
        access: proxy
        jsonData:
          httpHeaderName1: 'X-Scope-OrgID'
        secureJsonData:
          httpHeaderValue1: '1'
        EOT
  }
}
# Create Grafana Helm release. We want to creater it after Loki so that we camn use Loki as a datasource:
resource "helm_release" "monitoring" {
  depends_on = [
    kubernetes_namespace_v1.monitoring,
    helm_release.loki,
  ]
  name       = "monitoring-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_version
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  # kps 83 upgrades roll Grafana + Prometheus + Alertmanager — the default 5
  # min is too tight, especially on smaller non-EKS clusters.
  timeout = 900
  values = [
    templatefile("${path.module}/assets/helm-values-monitoring.tpl",
      {
        GRAFANA_PVC_SIZE                                        = var.grafana_pvc_size,
        GRAFANA_PVC_STORAGE_CLASS                               = var.grafana_pvc_storage_class,
        GRAFANA_GATEWAY_NAME                                    = var.grafana_gateway_parent_ref.name,
        GRAFANA_GATEWAY_NAMESPACE                               = var.grafana_gateway_parent_ref.namespace,
        GRAFANA_GATEWAY_SECTION                                 = var.grafana_gateway_parent_ref.section_name,
        GRAFANA_HOST                                            = var.grafana_host,
        GRAFANA_ADMIN_USER                                      = var.grafana_admin_user,
        GRAFANA_ADMIN_PASSWORD                                  = var.grafana_admin_password,
        GRAFANA_PLUGINS                                         = var.grafana_plugins,
        GRAFANA_OAUTH_ENABLED                                   = var.grafana_oauth_enabled,
        GRAFANA_OAUTH_NAME                                      = var.grafana_oauth_name,
        GRAFANA_OAUTH_CLIENT_ID                                 = var.grafana_oauth_client_id,
        GRAFANA_OAUTH_CLIENT_SECRET                             = var.grafana_oauth_client_secret,
        GRAFANA_OAUTH_SCOPES                                    = var.grafana_oauth_scopes,
        GRAFANA_OAUTH_AUTH_URL                                  = var.grafana_oauth_auth_url,
        GRAFANA_OAUTH_TOKEN_URL                                 = var.grafana_oauth_token_url,
        GRAFANA_OAUTH_API_URL                                   = var.grafana_oauth_api_url,
        GRAFANA_OAUTH_ROLE_ATTRIBUTE_PATH                       = var.grafana_oauth_role_attribute_path,
        GRAFANA_OAUTH_ROLE_ATTRIBUTE_STRICT                     = var.grafana_oauth_role_attribute_strict,
        GRAFANA_OAUTH_USE_REFRESH_TOKEN                         = var.grafana_oauth_use_refresh_token,
        GRAFANA_OAUTH_AUTO_LOGIN                                = var.grafana_oauth_auto_login,
        GRAFANA_OAUTH_SKIP_ORG_ROLE_SYNC                        = var.grafana_oauth_skip_org_role_sync,
        GRAFANA_AUTO_ASSIGN_ORG_ID                              = var.grafana_auto_assign_org_id,
        ALERT_MANAGER_GATEWAY_NAME                              = var.alert_manager_gateway_parent_ref.name,
        ALERT_MANAGER_GATEWAY_NAMESPACE                         = var.alert_manager_gateway_parent_ref.namespace,
        ALERT_MANAGER_GATEWAY_SECTION                           = var.alert_manager_gateway_parent_ref.section_name,
        ALERT_MANAGER_HOST                                      = var.alert_manager_host,
        ALERT_MANAGER_SLACK_WEBHOOK_URL                         = var.alert_manager_slack_webhook_url,
        ALERT_MANAGER_SLACK_WEBHOOK_URL_WEB_ENDPOINT_MONITORING = local.web_endpoint_monitoring_webhook,
        GRAFANA_EXTRA_DASHBOARD_PROVIDERS                       = var.grafana_extra_dashboard_providers,
      }
    )
  ]
}

# Grafana Alloy — log shipper. Replaces promtail (which the project archived
# in 2025). See
# https://hodovi.cc/blog/kubernetes-events-monitoring-with-loki-alloy-and-grafana/
# for the relabel-rules background.
resource "helm_release" "grafana_alloy" {
  depends_on = [
    kubernetes_namespace_v1.monitoring,
    helm_release.loki,
  ]
  name       = "alloy-v1"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.0.2"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  values = [
    <<-EOT
    controller:
      type: 'statefulset'
      replicas: 1

    alloy:
      configMap:
        create: true
        content: |
          logging {
            level = "info"
            format = "logfmt"
          }

          loki.source.kubernetes_events "events" {
            log_format = "json"
            forward_to = [loki.write.local.receiver]
          }

          discovery.kubernetes "pods" {
            role = "pod"
          }

          discovery.relabel "pods" {
            targets = discovery.kubernetes.pods.targets

            // Add namespace label
            rule {
              source_labels = ["__meta_kubernetes_namespace"]
              target_label  = "namespace"
            }

            // Add pod name
            rule {
              source_labels = ["__meta_kubernetes_pod_name"]
              target_label  = "pod"
            }

            // Add container name
            rule {
              source_labels = ["__meta_kubernetes_pod_container_name"]
              target_label  = "container"
            }

            // Add app label from pod labels
            rule {
              source_labels = ["__meta_kubernetes_pod_label_app"]
              target_label  = "app"
            }

            // Add app.kubernetes.io/name label
            rule {
              source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
              target_label  = "app_name"
            }

            // Add app.kubernetes.io/instance label
            rule {
              source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_instance"]
              target_label  = "app_instance"
            }

            // Extract deployment name from pod controller
            rule {
              source_labels = ["__meta_kubernetes_pod_controller_kind", "__meta_kubernetes_pod_controller_name"]
              separator     = ";"
              regex         = "ReplicaSet;(.+)-[a-z0-9]+"
              target_label  = "deployment"
            }

            // Add statefulset name if applicable
            rule {
              source_labels = ["__meta_kubernetes_pod_controller_kind", "__meta_kubernetes_pod_controller_name"]
              separator     = ";"
              regex         = "StatefulSet;(.+)"
              target_label  = "statefulset"
            }

            // Add daemonset name if applicable
            rule {
              source_labels = ["__meta_kubernetes_pod_controller_kind", "__meta_kubernetes_pod_controller_name"]
              separator     = ";"
              regex         = "DaemonSet;(.+)"
              target_label  = "daemonset"
            }

            // Add node name
            rule {
              source_labels = ["__meta_kubernetes_pod_node_name"]
              target_label  = "node"
            }

            // Keep only running pods
            rule {
              source_labels = ["__meta_kubernetes_pod_phase"]
              regex         = "Pending|Running"
              action        = "keep"
            }
          }

          loki.source.kubernetes "pods" {
            targets    = discovery.relabel.pods.output
            forward_to = [loki.write.local.receiver]
          }

          loki.write "local" {
            endpoint {
              url = "http://loki-write:3100/loki/api/v1/push"
            }
          }

    EOT
  ]
}


resource "helm_release" "blackbox_exporter" {
  count = var.blackbox_exporter ? 1 : 0

  depends_on = [
    kubernetes_namespace_v1.monitoring,
    helm_release.monitoring,
  ]
  name       = "blackbox-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-blackbox-exporter"
  version    = var.blackbox_exporter_version
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
}
