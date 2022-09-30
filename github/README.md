# Usage

This module can be used independently to create Github repos with Contiamo's standard repo settings already configured.

## Instructions:

- Create a new `vars.tfvars` file containing the repo name, description and collaborators with their permissions. Permission value must be one of "`pull`", "`push`", "`maintain`", "`triage`" or "`admin`":

    ```tfvars
    repo_name = "example-repo-name"
    repo_description = "Example repo description."
    repo_collaborators = { "[Github username]" = "[Github permission]"}
    ```

- Run:
    ```bash
    terraform init

    terraform plan -var-file=vars.tfvars -out=myPlan.tfplan
    terraform apply "myPlan.tfplan"
    ```
- Delete the newly created files so that they don't interfere with Project Ops:
    ```
    rm myPlan.tfplan terraform.tfstate terraform.tfstate.backup vars.tfvars
    rm -rf .terraform .terraform.lock.hcl
    ```
