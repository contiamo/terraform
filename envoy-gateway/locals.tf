# Static map of API paths produced by data.kubectl_file_documents for each
# supported chart version. Required because Terraform cannot determine
# for_each keys dynamically from file content at plan time.
#
# To add a new chart version, run scripts/update-envoy-crds.sh and
# commit the new envoy-crds-<version>.yaml file plus an entry here.
locals {
  chart_version_to_envoy_crds_map = {
    "v1.7.1" = [
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backends.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backendtrafficpolicies.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/clienttrafficpolicies.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/envoyextensionpolicies.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/envoypatchpolicies.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/envoyproxies.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/httproutefilters.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/securitypolicies.gateway.envoyproxy.io",
    ]
    "v1.7.2" = [
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backends.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backendtrafficpolicies.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/clienttrafficpolicies.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/envoyextensionpolicies.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/envoypatchpolicies.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/envoyproxies.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/httproutefilters.gateway.envoyproxy.io",
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/securitypolicies.gateway.envoyproxy.io",
    ]
  }
}
