locals {
  domain_name = "${lower(var.project_name)}-es-${var.environment}"
}

data "aws_vpc" "property_validation" {
  id = var.vpc_id
}

data "aws_caller_identity" "current" {}

resource "aws_security_group" "property_validation" {
  name        = lower("${var.project_name}-${var.environment}-es-sg")
  description = "Managed by Terraform"
  vpc_id      = data.aws_vpc.property_validation.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      data.aws_vpc.property_validation.cidr_block,
    ]
  }
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      data.aws_vpc.property_validation.cidr_block,
    ]
  }
  ingress {
    from_port = 9300
    to_port   = 9300
    protocol  = "tcp"

    cidr_blocks = [
      data.aws_vpc.property_validation.cidr_block,
    ]
  }
  ingress {
    from_port = 9200
    to_port   = 9200
    protocol  = "tcp"

    cidr_blocks = [
      data.aws_vpc.property_validation.cidr_block,
    ]
  }
  tags = var.aws_tags
}

resource "aws_iam_service_linked_role" "property_validation" {
  aws_service_name = "opensearchservice.amazonaws.com"
}

data "aws_iam_policy_document" "property_validation" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["es:*"]
    resources = [
      "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${local.domain_name}/*",
      "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${local.domain_name}"
    ]
  }
}

resource "aws_opensearch_domain" "property_validation" {
  depends_on = [aws_iam_service_linked_role.property_validation]

  domain_name             = local.domain_name
  engine_version          = "Elasticsearch_7.10"
  # engine_version          = "OpenSearch_2.11
  ebs_options {
    ebs_enabled = true
    volume_size = 70
  }
  cluster_config {
    instance_type          = var.elasticsearch_instance_type
    zone_awareness_enabled = false
    # instance_count         = 2
  }

  vpc_options {
    subnet_ids = [
      var.subnet_ids[0]
    ]

    security_group_ids = [aws_security_group.property_validation.id]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = data.aws_iam_policy_document.property_validation.json

  tags = var.aws_tags
}

output "endpoint" {
  value = aws_opensearch_domain.property_validation.endpoint
}
