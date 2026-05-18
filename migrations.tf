# State migrations from the previous `data.kubectl_file_documents`-based
# implementation, where `for_each` keys were API paths produced by the
# kubectl provider. The new keys are `<kind>/<metadata.name>` derived in
# pure HCL — see main.tf.
#
# These blocks are no-ops for callers who never installed the old
# implementation, and one-time state-address shifts for callers upgrading
# from any older module ref. Names cover both v1.7.1 and v1.7.2 (which
# share the same set of CRDs).

moved {
  from = kubectl_manifest.envoy_gateway_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backends.gateway.envoyproxy.io"]
  to   = kubectl_manifest.envoy_gateway_crds["CustomResourceDefinition/backends.gateway.envoyproxy.io"]
}

moved {
  from = kubectl_manifest.envoy_gateway_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backendtrafficpolicies.gateway.envoyproxy.io"]
  to   = kubectl_manifest.envoy_gateway_crds["CustomResourceDefinition/backendtrafficpolicies.gateway.envoyproxy.io"]
}

moved {
  from = kubectl_manifest.envoy_gateway_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/clienttrafficpolicies.gateway.envoyproxy.io"]
  to   = kubectl_manifest.envoy_gateway_crds["CustomResourceDefinition/clienttrafficpolicies.gateway.envoyproxy.io"]
}

moved {
  from = kubectl_manifest.envoy_gateway_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/envoyextensionpolicies.gateway.envoyproxy.io"]
  to   = kubectl_manifest.envoy_gateway_crds["CustomResourceDefinition/envoyextensionpolicies.gateway.envoyproxy.io"]
}

moved {
  from = kubectl_manifest.envoy_gateway_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/envoypatchpolicies.gateway.envoyproxy.io"]
  to   = kubectl_manifest.envoy_gateway_crds["CustomResourceDefinition/envoypatchpolicies.gateway.envoyproxy.io"]
}

moved {
  from = kubectl_manifest.envoy_gateway_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/envoyproxies.gateway.envoyproxy.io"]
  to   = kubectl_manifest.envoy_gateway_crds["CustomResourceDefinition/envoyproxies.gateway.envoyproxy.io"]
}

moved {
  from = kubectl_manifest.envoy_gateway_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/httproutefilters.gateway.envoyproxy.io"]
  to   = kubectl_manifest.envoy_gateway_crds["CustomResourceDefinition/httproutefilters.gateway.envoyproxy.io"]
}

moved {
  from = kubectl_manifest.envoy_gateway_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/securitypolicies.gateway.envoyproxy.io"]
  to   = kubectl_manifest.envoy_gateway_crds["CustomResourceDefinition/securitypolicies.gateway.envoyproxy.io"]
}
