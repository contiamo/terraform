# Slack Module

This module creates a Slack channel and adds provided users (references by their emails) to it.

## Instructions:

### Use Independently:
- Create a new `vars.tfvars` file containing the following values:

    ```tfvars
    channel_name = [channel name]
    channel_topic = [channel description]
    channel_members = {"email@contiamo.com", "email2@contiamo.com"}
    ```

- Run:
    ```bash
    terraform init

    terraform plan -var-file=vars.tfvars -out=myPlan.tfplan
    terraform apply "myPlan.tfplan"
    ```

### Reference In another TF Project:
```terraform
module "slack" {
    source = "git@github.com:contiamo/terraform.git//slack"
    channel_name = "[new channel name]"
    channel_topic = "[new channel description]"
    channel_members = [list of user emails]
}
```