# Terraform
Contains Terraform modules.
## Usage

- Modules stored in this repo can be referenced in other projects:
    ```terraform
    module "slack" {
        source = "git@github.com:contiamo/terraform.git//slack"
        channel_name = "[your value]"
        ...
    }
    ```
    It is also possible to pin a module version:

    ```terraform
    module "slack" {
        source = "git@github.com:contiamo/terraform.git//slack?ref=tags/v0.1.0"
        channel_name = "[your value]"
        ...
    }
    ```
- Refer to individual module docs for examples.


