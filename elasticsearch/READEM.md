# Property Validation Elasticsearch Module

This module creates an Elasticsearch (AWS OpenSearch) cluster in AWS using Terraform.

The resource will be created in the VPC that is specified by your variables, and it will set up the necessary security groups and IAM roles for access.

## Usage

### Reference In Another Project:

```terraform
module "property_validation_es" {
  source = "github.com/<your-org>/terraform-modules//property-validation-es"
  project_name              = "[your project name]"
  environment               = "[your environment]"
  vpc_id                    = "[VPC ID]"
  subnet_ids                = ["[Subnet ID]"]
  elasticsearch_instance_type = "[Instance type]"
  aws_region                = "[AWS Region]"
  aws_tags                  = {
    "Name" = "[Resource name]"
    // other tags
  }
}
```

### Use Independently:
- Set values for the required variables and save it in `vars.tfvars`:
    ```bash
    project_name               = "[your project name]"
    environment                = "[your environment]"
    vpc_id                     = "[VPC ID]"
    subnet_ids                 = ["[Subnet ID]"]
    elasticsearch_instance_type = "[Instance type]"
    aws_region                 = "[AWS Region]"
    aws_tags = {
      "Name" = "[Resource name]"
      // additional tags
    }
    ```
- Initialise Terraform:
    ```bash
    terraform init
    ```
    Terraform will prompt you for a path to your state file in a state bucket. To bypass this prompt, you can include this value in the `terraform {}` block at the top of your `main.tf` file.
- Plan:
    ```bash
    terraform plan -out=es_plan.tfplan
    ```
- Create the resources:
    ```bash
    terraform apply "es_plan.tfplan"
    ```

## Inputs

| Name | Description | Type | Required |
|------|-------------|:----:|:--------:|
| project_name | The name of the project. | `string` | yes |
| environment | Target environment. Must be one of: `dev`, `stg`, `prod`. | `string` | yes |
| aws_region | AWS region to deploy to. | `string` | yes |
| subnet_ids | Subnet IDs to use for the Elasticsearch cluster. | `list(string)` | yes |
| vpc_id | VPC ID to use for the Elasticsearch cluster. | `string` | yes |
| elasticsearch_instance_type | Instance type to use for the Elasticsearch cluster. | `string` | yes |
| aws_tags | A map of tags to assign to the resources. | `map(string)` | yes |


## Outputs
- `endpoint`: The endpoint of the created Elasticsearch domain.

Replace placeholder values like `[your project name]`, `[your environment]`, and other placeholders with actual values relevant to your project.
