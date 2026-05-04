# Gateway API CRDs — installed from the official upstream standard-install.yaml.
# File source: https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.crd_version}/standard-install.yaml
#
# The static YAML file is parsed in pure HCL: `split` separates the multi-doc
# stream, `yamldecode` parses each document, and `for_each` keys are computed
# at plan time from the resulting map. This sidesteps the kubectl provider's
# `data.kubectl_file_documents` deferred-read behaviour, which was causing
# every `tofu plan` to mark each `kubectl_manifest` as "update in-place"
# (yaml_body `(known after apply)`) even when the file was unchanged.
#
# Key shape: `<kind>/<metadata.name>` — disambiguates the
# ValidatingAdmissionPolicy + ValidatingAdmissionPolicyBinding pair that share
# the name `safe-upgrades.gateway.networking.k8s.io`.
locals {
  # Split the multi-doc YAML on `---` separators. Some chunks may be the
  # file's leading license/comment block (no actual YAML document) — skip
  # any chunk that doesn't yamldecode to an object with a `kind` field.
  crd_docs = [
    for doc in split("\n---\n", file("${path.module}/crds/${var.crd_version}-standard-install.yaml")) :
    yamldecode(doc) if can(yamldecode(doc)) && try(yamldecode(doc).kind, null) != null
  ]
  crd_map = {
    for d in local.crd_docs : "${d.kind}/${d.metadata.name}" => d
  }
}

resource "kubectl_manifest" "gateway_api_crds" {
  for_each          = local.crd_map
  yaml_body         = yamlencode(each.value)
  server_side_apply = true
  force_conflicts   = true
  wait              = true
}
