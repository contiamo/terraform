# State migrations from the previous `data.kubectl_file_documents`-based
# implementation, where `for_each` keys were API paths produced by the
# kubectl provider. The new keys are `<kind>/<metadata.name>` derived in
# pure HCL — see main.tf.
#
# These blocks are no-ops for callers who never installed the old
# implementation, and one-time state-address shifts for callers upgrading
# from any older module ref.

moved {
  from = kubectl_manifest.gateway_api_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backendtlspolicies.gateway.networking.k8s.io"]
  to   = kubectl_manifest.gateway_api_crds["CustomResourceDefinition/backendtlspolicies.gateway.networking.k8s.io"]
}

moved {
  from = kubectl_manifest.gateway_api_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/gatewayclasses.gateway.networking.k8s.io"]
  to   = kubectl_manifest.gateway_api_crds["CustomResourceDefinition/gatewayclasses.gateway.networking.k8s.io"]
}

moved {
  from = kubectl_manifest.gateway_api_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/gateways.gateway.networking.k8s.io"]
  to   = kubectl_manifest.gateway_api_crds["CustomResourceDefinition/gateways.gateway.networking.k8s.io"]
}

moved {
  from = kubectl_manifest.gateway_api_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/grpcroutes.gateway.networking.k8s.io"]
  to   = kubectl_manifest.gateway_api_crds["CustomResourceDefinition/grpcroutes.gateway.networking.k8s.io"]
}

moved {
  from = kubectl_manifest.gateway_api_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/httproutes.gateway.networking.k8s.io"]
  to   = kubectl_manifest.gateway_api_crds["CustomResourceDefinition/httproutes.gateway.networking.k8s.io"]
}

moved {
  from = kubectl_manifest.gateway_api_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/listenersets.gateway.networking.k8s.io"]
  to   = kubectl_manifest.gateway_api_crds["CustomResourceDefinition/listenersets.gateway.networking.k8s.io"]
}

moved {
  from = kubectl_manifest.gateway_api_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/referencegrants.gateway.networking.k8s.io"]
  to   = kubectl_manifest.gateway_api_crds["CustomResourceDefinition/referencegrants.gateway.networking.k8s.io"]
}

moved {
  from = kubectl_manifest.gateway_api_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/tlsroutes.gateway.networking.k8s.io"]
  to   = kubectl_manifest.gateway_api_crds["CustomResourceDefinition/tlsroutes.gateway.networking.k8s.io"]
}

moved {
  from = kubectl_manifest.gateway_api_crds["/apis/admissionregistration.k8s.io/v1/validatingadmissionpolicys/safe-upgrades.gateway.networking.k8s.io"]
  to   = kubectl_manifest.gateway_api_crds["ValidatingAdmissionPolicy/safe-upgrades.gateway.networking.k8s.io"]
}

moved {
  from = kubectl_manifest.gateway_api_crds["/apis/admissionregistration.k8s.io/v1/validatingadmissionpolicybindings/safe-upgrades.gateway.networking.k8s.io"]
  to   = kubectl_manifest.gateway_api_crds["ValidatingAdmissionPolicyBinding/safe-upgrades.gateway.networking.k8s.io"]
}
