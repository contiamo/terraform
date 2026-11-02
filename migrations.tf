# State migration from the previous `data.kubectl_file_documents`-based
# implementation, where the `for_each` key was an API path produced by
# the kubectl provider. The new key is `<kind>/<metadata.name>` derived
# in pure HCL — see main.tf.
#
# This block is a no-op for callers who never installed the old
# implementation, and a one-time state-address shift for callers
# upgrading from any older module ref.

moved {
  from = kubectl_manifest.onepassword_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/onepassworditems.onepassword.com"]
  to   = kubectl_manifest.onepassword_crds["CustomResourceDefinition/onepassworditems.onepassword.com"]
}
