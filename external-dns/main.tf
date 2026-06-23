# IAM policy granting the external-dns service account permission to
# manage records in the target Route53 hosted zone.
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
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource" : [
          "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        "Resource" : [
          "*"
        ]
      },
    ]
  })
}

module "iam_eks_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  # Pin to v5.x: v6 renamed this submodule (dropped the `-eks` suffix) and
  # changed its interface, so the unpinned reference broke on fresh init.
  version = "~> 5.0"

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
    name      = "external-dns"
    namespace = var.k8s_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = "${module.iam_eks_role.iam_role_arn}"
    }
  }
}

moved {
  from = helm_release.property_validation
  to   = helm_release.external_dns
}

resource "helm_release" "external_dns" {
  depends_on = [kubernetes_service_account_v1.external_dns]
  provider   = helm
  name       = "external-dns"
  # Official kubernetes-sigs chart (was the Bitnami chart, whose images moved
  # to the unmaintained `bitnamilegacy` catalogue in Aug 2025). Same release
  # name, so this is an in-place `helm upgrade` — external-dns is stateless and
  # Route 53 records persist; the new release adopts the existing records via
  # the unchanged `txtOwnerId` (= hosted_zone_id) in the TXT ownership registry.
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  version          = var.helm_chart_version
  namespace        = var.k8s_namespace
  max_history      = 3
  timeout          = 600
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  reset_values     = true # chart swap: start from sigs chart defaults, not leftover Bitnami values

  values = [
    yamlencode({
      provider = { name = "aws" }
      policy   = "sync"
      registry = "txt"
      # Keep the TXT ownership id identical to the Bitnami deployment so the
      # new external-dns recognises and continues managing the existing records.
      txtOwnerId    = var.hosted_zone_id
      domainFilters = [var.aws_route53_domain]
      serviceAccount = {
        # The module manages the ServiceAccount (with the IRSA annotation), so
        # the chart must not create its own.
        create = false
        name   = "external-dns"
      }
      # The sigs chart has no `aws.region` value; pass the region via env.
      # (external-dns also auto-detects it from IMDS/STS if omitted.)
      env = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = var.aws_region
        },
      ]
    })
  ]
}
