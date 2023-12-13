resource "aws_iam_policy" "policy" {
  name        = var.project_name
  path        = "/"
  description = "Used by external dns eks addon to create dns records in route53"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource": [
            "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
        ]
      },
        {
        "Effect": "Allow",
        "Action": [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets"
        ],
        "Resource": [
            "*"
        ]
      },
    ]
  })
}

module "iam_eks_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = var.project_name
  role_policy_arns = {
    "external-dns" = aws_iam_policy.policy.arn
  }
  oidc_providers = {
    main = {
      provider_arn               = var.provider_arn
      namespace_service_accounts = ["${var.k8s_namespace}:external-dns"]
    }
  }
}
resource "kubernetes_service_account_v1" "external_dns" {
  metadata {
    name = "external-dns"
    namespace = var.k8s_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = "${module.iam_eks_role.iam_role_arn}"
    }
  }
}

resource "helm_release" "property_validation" {
  depends_on = [ kubernetes_service_account_v1.external_dns ]
  provider         = helm
  name             = "external-dns"
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  chart            = "external-dns"
  namespace        = var.k8s_namespace
  max_history      = 3
  timeout          = 600
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  reset_values     = true
  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "txtOwnerId"
    value = var.hosted_zone_id
  }

  set {
    name  = "domainFilters[0]"
    value = var.aws_route53_domain
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "policy"
    value = "sync"
  }
}