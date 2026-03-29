# Static map of API paths per version, required because Terraform cannot
# determine for_each keys dynamically from file content at plan time.
#
# To find the keys for a new version, run:
#   tofu plan -target=data.kubectl_file_documents.gateway_api_crds
# and inspect the manifests map keys in the output.
locals {
  version_to_crds_map = {
    "v1.5.1" = [
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backendtlspolicies.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/gatewayclasses.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/gateways.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/grpcroutes.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/httproutes.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/listenersets.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/referencegrants.gateway.networking.k8s.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/tlsroutes.gateway.networking.k8s.io",
      "/apis/admissionregistration.k8s.io/v1/validatingadmissionpolicys/safe-upgrades.gateway.networking.k8s.io",
      "/apis/admissionregistration.k8s.io/v1/validatingadmissionpolicybindings/safe-upgrades.gateway.networking.k8s.io",
    ]
  }
}
