variable "cluster_oidc_issuer_url" {
  description = "The EKS cluster's OIDC issuer URL (e.g. https://oidc.eks.eu-central-1.amazonaws.com/id/XXXX). Used to build the IRSA trust policy."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster's IAM OIDC provider. The IRSA role trusts this federated principal."
  type        = string
}

variable "route53_zone_ids" {
  description = "Route 53 hosted zone IDs external-dns is allowed to write records into. Scopes the route53:ChangeResourceRecordSets permission to exactly these zones."
  type        = list(string)
}

variable "helm_chart_version" {
  description = <<-EOT
    Version of the external-dns Helm chart (https://kubernetes-sigs.github.io/external-dns).
    Chart 1.21.1 ships external-dns app v0.21.0, the first release whose binary
    supports `--gateway-listener-sets` (see `enable_gateway_listener_sets`).
  EOT
  type        = string
  default     = "1.21.1"
}

variable "namespace" {
  description = "Namespace the external-dns Helm release is deployed into."
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Name of the external-dns ServiceAccount (the chart creates it; the IRSA trust policy binds to it)."
  type        = string
  default     = "external-dns"
}

variable "role_name" {
  description = <<-EOT
    Name of the IRSA IAM role (and its attached policy). Defaults to the name the
    previous lablabs module used (`external-dns-irsa-external-dns`) so that an
    in-place migration imports the existing role/policy cleanly rather than
    creating new ones.
  EOT
  type        = string
  default     = "external-dns-irsa-external-dns"
}

variable "policy" {
  description = "external-dns sync policy: how DNS records are reconciled. One of `sync`, `upsert-only`, `create-only`."
  type        = string
  default     = "sync"
}

variable "sources" {
  description = "Kubernetes resource types external-dns watches for DNS records."
  type        = list(string)
  default     = ["service", "ingress", "gateway-httproute", "gateway-grpcroute"]
}

variable "enable_gateway_listener_sets" {
  description = <<-EOT
    Enable the chart's `enableGatewayListenerSets` value, which adds
    `--gateway-listener-sets` to external-dns. Lets a gateway-httproute whose
    parentRef is a Gateway API ListenerSet get a DNS record. Requires Gateway
    API v1.5+ CRDs in the cluster.
  EOT
  type        = bool
  default     = true
}

variable "aws_partition" {
  description = "AWS partition for the Route 53 hosted-zone ARNs (e.g. `aws`, `aws-cn`, `aws-us-gov`)."
  type        = string
  default     = "aws"
}

variable "tags" {
  description = "Tags applied to the IAM role and policy."
  type        = map(string)
  default     = {}
}
