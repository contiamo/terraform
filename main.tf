# Gateway API CRDs — installed from the official upstream standard-install.yaml.
# File source: https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.crd_version}/standard-install.yaml

data "kubectl_file_documents" "gateway_api_crds" {
  content = file("${path.module}/crds/${var.crd_version}-standard-install.yaml")
}

resource "kubectl_manifest" "gateway_api_crds" {
  for_each          = toset(local.version_to_crds_map[var.crd_version])
  yaml_body         = data.kubectl_file_documents.gateway_api_crds.manifests[each.value]
  server_side_apply = true
  force_conflicts   = true
  wait              = true
}
