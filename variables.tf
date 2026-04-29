variable "aws_secret_access_key" {
  description = "AWS secret access key for an IAM user with access to ECR"
  type        = string
}
variable "aws_access_key_id" {
  description = "AWS access key id for an IAM user with access to ECR"
  type        = string
}
variable "aws_region" {
  description = "AWS region where the ECR registry is located. Can be obtained by the resource"
  type        = string
}
variable "aws_account_id" {
  description = <<-EOF
    The ID of the AWS account ID where your the ECR lives.
    Can be obtained by the resource:
    data "aws_caller_identity" "current" {}
    And then:
    data.aws_caller_identity.current.account_id
  EOF
  type        = string
}
variable "ecr_registry_secret_name" {
  description = "The name of the secret that will be managed by this tool. This secret will contain temporary Docker creds for ECR"
  type        = string
  default     = "ecr-registry-pull-creds"
}

variable "ecr_helper_svc_account_name" {
  description = "The name of the service account that will be used by the ecr-registry-helper cronjob"
  type        = string
  default     = "ecr-helper"
}
variable "ecr_helper_namespace" {
  description = "The name of the namespace where the ecr-registry-helper cronjob will run"
  type        = string
  default     = "ecr-helper"
}
