# ECR Pull Helper

This module  sets up a cronjob that keeps temporary Docker credentials for ECR up to date in all namespaces.

## Usage:


```hcl
module "ecr_helper" {
  source = "github.com/contiamo/terraform//ecr-helper-module"

  aws_secret_access_key       = [AWS secrets access key for a user with read-only ECR access]
  aws_access_key_id           = [AWS secret access key ID for a user with read-only ECR access]
  aws_region                  = [AWS region where your ECR lives]
  ecr_helper_namespace        = [The name of the namespace that will be created for the cronjob. Default: "ecr-helper"]
  ecr_helper_svc_account_name = [The name of the service account that will be created for the cronjob. Default: "ecr-helper"]
  ecr_registry_secret_name    = [The name of the Docker credential secrets that will be managed for you in all namespaces. Default: "ecr-registry-secret"]
}
```
