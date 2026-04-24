# Static map of API paths produced by data.kubectl_file_documents for each
# supported chart version. Required because Terraform cannot determine
# for_each keys dynamically from file content at plan time.
#
# To add a new chart version, run scripts/update-onepassword-crds.sh and
# commit the new onepassword-crd-<version>.yaml file plus an entry here.
locals {
  chart_version_to_crds_map = {
    "2.4.1" = [
      "/apis/apiextensions.k8s.io/v1/customresourcedefinitions/onepassworditems.onepassword.com",
    ]
  }
}
