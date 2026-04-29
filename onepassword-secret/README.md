# 1Password Secret Module

This module retrieves a secret field value from a 1Password item. It looks up a vault by name, finds an item by title, and extracts a specific field value, optionally filtering by section.

## Instructions:

### Reference In Another TF Project:

```terraform
module "onepassword_secret" {
    # To reference as a private repo use "git@github.com:/contiamo...:
    # source = "git@github.com:contiamo/terraform.git//onepassword-secret"
    # contiamo-release-please-bump-start
    source = "github.com/contiamo/terraform//onepassword-secret?ref=v0.20.2"
    # contiamo-release-please-bump-end
    vault_name = "My Vault"
    item_name  = "My Secret Item"
    field      = "password"
    # section  = "tf-friendly"  # Optional: defaults to "tf-friendly", set to null to search all sections
}

# Access the secret value
resource "example_resource" "example" {
    password = module.onepassword_secret.value
}
```

### Use Independently:

- Create a new `vars.tfvars` file containing the following values:

  ```tfvars
  vault_name = "My Vault"
  item_name  = "My Secret Item"
  field      = "password"
  section    = "tf-friendly"  # Optional: set to null to search all sections
  ```

- Run:

  ```bash
  terraform init

  terraform plan -var-file=vars.tfvars -out=myPlan.tfplan
  terraform apply "myPlan.tfplan"
  ```

## Variables

| Name         | Description                                                               | Type     | Default         | Required |
| ------------ | ------------------------------------------------------------------------- | -------- | --------------- | -------- |
| `vault_name` | Name of the 1Password vault                                               | `string` | -               | Yes      |
| `item_name`  | Title of the 1Password item                                               | `string` | -               | Yes      |
| `field`      | Field label to extract                                                    | `string` | -               | Yes      |
| `section`    | Section label containing the field (set to `null` to search all sections) | `string` | `"tf-friendly"` | No       |

## Outputs

| Name    | Description            | Sensitive |
| ------- | ---------------------- | --------- |
| `value` | The secret field value | Yes       |

## Provider Requirements

This module requires the 1Password Terraform provider:

```terraform
terraform {
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = ">= 1.4.0"
    }
  }
}
```
