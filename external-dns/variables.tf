variable "project_name" {
  type        = string
  description = "Project name. All the resources will be given this name"
  default = "external-dns"
}
variable "provider_arn" {
  type        = string
  description = "OIDC provider ARN"
}
variable "k8s_namespace" {
  type        = string
  description = "K8S namespace"
}
variable "hosted_zone_id" {
  type        = string
  description = "Hosted zone ID"
}
variable "aws_region" {
  type = string
}
variable "aws_route53_domain" {
  type = string
  description = "Domain to use with EKS External DNS addon"
}
