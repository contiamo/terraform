# Datahub Terraform Module

This module installs [Datahub](https://datahubproject.io) using Helm.

The release will be installed into the cluster to which your kubectl config is currently pointing.

## Usage

### Reference In Another Project:

```terraform
module "datahub" {
  # To reference as a private repo use "git@github.com:/contiamo...:
  # source = "git@github.com:contiamo/terraform.git//datahub"
  # contiamo-release-please-bump-start
  source = "github.com/contiamo/terraform//datahub?ref=v0.9.0"
  # contiamo-release-please-bump-end
  datahub_namespace = "[your namespace]"
  ui_ingress_host = "[UI domain]"
  api_ingress_host = "[API domain]"
}
```

### Use Independently:
- Set values for the required variables and save it in `vars.tfvars`:
    ```bash
    datahub_namespace = "[your namespace]"
    ui_ingress_host = "[UI domain]"
    api_ingress_host = "[API domain]"
    # If your desired ingress class is not "nginx" set the value here:
    ingress_class = ""
    ```
- Initialise Terraform:
    ```bash
    terraform init
    ```
    Terraform will ask you to give the path to your state file in the state bucket. To avoid having to specify thi value add it to the `terraform {}` block in the top of the `datahub.tf` file.
- Plan:
    ```bash
    terraform plan -out=datahubplan.tfplan
    ```
- Create the stack:
    ```bash
    terraform apply "datahubplan.tfplan"
    ```
