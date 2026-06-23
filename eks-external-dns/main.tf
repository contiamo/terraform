# external-dns on EKS: an IRSA role scoped to the given Route 53 zones plus the
# external-dns Helm release wired to assume it. Purpose-built replacement for
# the lablabs/eks-external-dns module — only the slice we actually use, and free
# of the deprecated `managed_policy_arns` / non-`_v1` kubernetes resources that
# the generic lablabs addon framework carries.

locals {
  # The OIDC issuer host without the scheme, used to key the trust-policy
  # condition (e.g. oidc.eks.eu-central-1.amazonaws.com/id/XXXX).
  oidc_host = replace(var.cluster_oidc_issuer_url, "https://", "")
}

# Route 53 permissions: write records only into the allowed hosted zones; the
# list/read actions can't be zone-scoped so they stay on "*".
data "aws_iam_policy_document" "this" {
  statement {
    sid     = "ChangeResourceRecordSets"
    effect  = "Allow"
    actions = ["route53:ChangeResourceRecordSets"]
    resources = formatlist(
      "arn:%s:route53:::hostedzone/%s",
      var.aws_partition,
      var.route53_zone_ids,
    )
  }

  statement {
    sid    = "ListResourceRecordSets"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "this" {
  name = var.role_name
  # `description` is ForceNew on aws_iam_policy; keep the string the previous
  # lablabs module used so the migration imports in place instead of replacing.
  description = "Policy for ${var.role_name} addon"
  path        = "/"
  policy      = data.aws_iam_policy_document.this.json
  tags        = var.tags
}

# IRSA role: trusts the cluster OIDC provider for exactly the external-dns
# ServiceAccount. Matches the trust shape the previous module produced (only a
# `:sub` condition, no `:aud`) so the migration import is a no-op.
resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "helm_release" "this" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  version          = var.helm_chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = false

  # Mirrors the rendered values of the previous module: bind the chart's
  # ServiceAccount to the IRSA role, run the AWS provider, create RBAC.
  values = [
    yamlencode({
      provider  = { name = "aws" }
      rbac      = { create = true }
      extraArgs = []
      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
        }
      }
    })
  ]

  set = concat(
    [
      { name = "policy", value = var.policy },
      { name = "sources", value = "{${join(",", var.sources)}}" },
    ],
    var.enable_gateway_listener_sets ? [
      { name = "enableGatewayListenerSets", value = "true" },
    ] : [],
  )
}
