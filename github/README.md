# Github Module

This module can be used to create Github repos with Contiamo's standard repo settings already configured.

## Instructions:

### Use Independently:
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
### Reference In another TF Project:
```terraform
module "github" {
    source = "git@github.com:contiamo/terraform.git//github"
    repo_name = var.project_name
    repo_description = var.project_description
    repo_collaborators = local.users_to_add_as_github_collaborators
}
```
