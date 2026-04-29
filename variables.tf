variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable environment {
  description = "Target environment"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "The environment must be one of: dev, stg, or prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type = string
}

variable "subnet_ids" {
  description = "The subnet IDs to use for the the cluster"
  type        = list(string)
}

variable vpc_id {
  description = "The VPC ID to use for the Elasticsearch cluster"
  type        = string
}

variable "elasticsearch_instance_type" {
  description = "The instance type to use for the Elasticsearch cluster"
  type        = string
}
variable "aws_tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
}