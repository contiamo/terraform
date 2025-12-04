# Github Module

This module can be used to create Github repos with Contiamo's standard repo settings already configured.

## Instructions:

### Reference In Another TF Project:
```terraform
module "github" {
    # To reference as a private repo use "git@github.com:/contiamo...:
    # source = "git@github.com:contiamo/terraform.git//github"
    # contiamo-release-please-bump-start
    source = "github.com/contiamo/terraform//github?ref=v0.9.0"
    # contiamo-release-please-bump-end
    repo_name = var.project_name
    repo_description = var.project_description
    repo_collaborators = local.users_to_add_as_github_collaborators
}
```

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
