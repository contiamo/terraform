# Datahub Terraform Module

This module installs [Datahub](https://datahubproject.io) using Helm.

The release will be installed into the cluster to which your kubectl config is currently pointing.

## Usage
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
