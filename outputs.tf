output "irsa_role_arn" {
  description = "ARN of the IRSA role external-dns assumes."
  value       = aws_iam_role.this.arn
}

output "irsa_role_name" {
  description = "Name of the IRSA role."
  value       = aws_iam_role.this.name
}

output "irsa_policy_arn" {
  description = "ARN of the Route 53 policy attached to the IRSA role."
  value       = aws_iam_policy.this.arn
}

output "helm_release_name" {
  description = "Name of the external-dns Helm release."
  value       = helm_release.this.name
}

output "namespace" {
  description = "Namespace external-dns is deployed into."
  value       = var.namespace
}
