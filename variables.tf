variable "chart_version" {
  description = <<-EOT
    Karpenter version. Drives the controller chart, the four CRDs, and the
    image tag bundled in the chart. Named `chart_version` (not `version`)
    because Terraform reserves `version` as a module-block meta-argument.

    Must be one of the versions tracked in locals.tf (`supported_versions`).
    New versions are added automatically by the daily update-karpenter
    workflow, or manually via:
      ./karpenter/scripts/update-karpenter.sh <new-version>

    See: https://github.com/aws/karpenter-provider-aws/releases
  EOT
  type        = string
  default     = "1.12.0"
}

variable "namespace" {
  description = "Kubernetes namespace for the Karpenter controller. The chart's defaults assume `karpenter`; override only when bootstrapping a non-standard cluster."
  type        = string
  default     = "karpenter"
}

variable "release_name" {
  description = "Helm release name for the Karpenter controller. Default `karpenter` matches the chart's documented install."
  type        = string
  default     = "karpenter"
}

# ----------------------------------------------------------------------------
# Required cluster-binding inputs (no sensible defaults)
# ----------------------------------------------------------------------------

variable "cluster_name" {
  description = "EKS cluster name (passed to the controller as `settings.clusterName`)."
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS API server endpoint (passed as `settings.clusterEndpoint`)."
  type        = string
}

variable "interruption_queue" {
  description = "SQS queue name for spot interruption notices (passed as `settings.interruptionQueue`). Typically `module.karpenter.queue_name` from terraform-aws-modules/eks/aws/modules/karpenter."
  type        = string
}

variable "service_account_role_arn" {
  description = "IRSA role ARN annotated on the controller's ServiceAccount (`eks.amazonaws.com/role-arn`)."
  type        = string
}

# ----------------------------------------------------------------------------
# Optional controller config (sensible defaults)
# ----------------------------------------------------------------------------

variable "replicas" {
  description = "Controller replica count. Default 2 for HA."
  type        = number
  default     = 2
}

variable "tolerations" {
  description = "Tolerations for the controller pod. Default tolerates the EKS-managed Fargate profile so the controller can land before any data-plane node exists."
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  default = [
    {
      key      = "eks.amazonaws.com/compute-type"
      operator = "Equal"
      value    = "fargate"
      effect   = "NoSchedule"
    }
  ]
}

variable "webhook" {
  description = "Conversion webhook configuration. Required by Karpenter v1 CRDs; defaults match the upstream chart."
  type = object({
    enabled = optional(bool, true)
    port    = optional(number, 8443)
  })
  default = {}
}

variable "extra_values" {
  description = "Additional Helm values merged into the rendered values. Use for cluster-specific tweaks not exposed as first-class variables."
  type        = any
  default     = {}
}
