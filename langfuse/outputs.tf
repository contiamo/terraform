output "langfuse_namespace" {
  description = "The Kubernetes namespace where Langfuse is deployed"
  value       = var.langfuse_namespace
}

output "langfuse_url" {
  description = "The URL where Langfuse UI is accessible"
  value       = "https://${var.langfuse_host}"
}

output "langfuse_internal_url" {
  description = "The internal Kubernetes service URL for Langfuse"
  value       = "http://langfuse-web.${var.langfuse_namespace}.svc.cluster.local:3000"
}

output "public_key" {
  description = "Langfuse project public key for SDK integration"
  value       = kubernetes_secret_v1.langfuse_admin.data["LANGFUSE_INIT_PROJECT_PUBLIC_KEY"]
  sensitive   = true
}

output "secret_key" {
  description = "Langfuse project secret key for SDK integration"
  value       = kubernetes_secret_v1.langfuse_admin.data["LANGFUSE_INIT_PROJECT_SECRET_KEY"]
  sensitive   = true
}

output "instructions" {
  description = "Instructions for retrieving credentials and accessing Langfuse"
  value       = <<-EOT
    ================================================================================
    Langfuse
    ================================================================================

    Access Points:
      - Langfuse UI: https://${var.langfuse_host}
      - Internal URL: http://langfuse-web.${var.langfuse_namespace}.svc.cluster.local:3000

    ================================================================================
    Retrieve Credentials
    ================================================================================

    # Admin email
    kubectl -n ${var.langfuse_namespace} get secret langfuse-admin -o jsonpath="{.data.admin-email}" | base64 --decode

    # Admin password
    kubectl -n ${var.langfuse_namespace} get secret langfuse-admin -o jsonpath="{.data.admin-password}" | base64 --decode

    # Public key (for SDK integration)
    kubectl -n ${var.langfuse_namespace} get secret langfuse-admin -o jsonpath="{.data.LANGFUSE_INIT_PROJECT_PUBLIC_KEY}" | base64 --decode

    # Secret key (for SDK integration)
    kubectl -n ${var.langfuse_namespace} get secret langfuse-admin -o jsonpath="{.data.LANGFUSE_INIT_PROJECT_SECRET_KEY}" | base64 --decode

    ================================================================================
  EOT
}
