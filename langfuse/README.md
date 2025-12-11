# Langfuse Terraform Module

This module deploys [Langfuse](https://langfuse.com), an open-source LLM engineering platform for observability, metrics, evaluations, and prompt management.

The module deploys a complete Langfuse stack on Kubernetes including:
- Langfuse web application
- PostgreSQL database
- ClickHouse for analytics
- Valkey (Redis) for caching
- MinIO for S3-compatible object storage

## Requirements

| Name       | Version  |
| ---------- | -------- |
| terraform  | >= 1.3.0 |
| kubernetes | >= 2.0   |
| helm       | >= 2.0   |
| random     | >= 3.0   |

## Prerequisites

- A Kubernetes cluster with sufficient resources
- cert-manager installed for TLS certificates (see [cert-manager module](../cert-manager))
- An Ingress controller (e.g., nginx-ingress)
- DNS configured to point your domain to the Ingress controller

## Usage

### Reference In Another Project:

```terraform
module "langfuse" {
  # To reference as a private repo use "git@github.com:/contiamo...:
  # source = "git@github.com:contiamo/terraform.git//langfuse"
  # contiamo-release-please-bump-start
  source = "github.com/contiamo/terraform//langfuse?ref=v0.9.0"
  # contiamo-release-please-bump-end

  langfuse_host          = "langfuse.example.com"
  admin_email            = "admin@example.com"
  org_id                 = "my-org"
  org_name               = "My Organisation"
  project_id             = "my-project"
  project_name           = "My Project"

  # Optional: customise settings
  chart_version                = "1.0.0"
  clickhouse_volume_size       = "100Gi"
  s3_volume_size               = "100Gi"
  ingress_class_name           = "nginx"
  cert_manager_cluster_issuer  = "letsencrypt-production"
}

# Access the credentials
output "langfuse_access" {
  value = module.langfuse.instructions
}
```

### Complete Example with Application Integration

```terraform
# Deploy Langfuse
module "langfuse" {
  # contiamo-release-please-bump-start
  source = "github.com/contiamo/terraform//langfuse?ref=v0.9.0"
  # contiamo-release-please-bump-end

  langfuse_host          = "langfuse.mycompany.io"
  admin_email            = "platform@mycompany.io"
  org_id                 = "mycompany"
  org_name               = "My Company"
  project_id             = "ai-platform-prod"
  project_name           = "AI Platform Production"
  chart_version          = "1.0.0"
  clickhouse_volume_size = "200Gi"
  s3_volume_size         = "150Gi"
}

# Create Kubernetes secret for your application to use
resource "kubernetes_secret_v1" "app_langfuse_creds" {
  metadata {
    name      = "langfuse-creds"
    namespace = "my-app-namespace"
  }

  data = {
    LANGFUSE_PUBLIC_KEY = module.langfuse.public_key
    LANGFUSE_SECRET_KEY = module.langfuse.secret_key
    LANGFUSE_HOST       = module.langfuse.langfuse_internal_url
  }

  type = "Opaque"
}

# Display access instructions
output "langfuse_instructions" {
  description = "Instructions for accessing Langfuse"
  value       = module.langfuse.instructions
}
```

### Use Independently:

1. Create a `vars.tfvars` file with required values:

```tfvars
langfuse_host = "langfuse.example.com"
admin_email   = "admin@example.com"
org_id        = "my-org"
org_name      = "My Organisation"
project_id    = "my-project"
project_name  = "My Project"
chart_version = "1.0.0"
```

2. Initialise Terraform:

```bash
terraform init
```

3. Plan and apply:

```bash
terraform plan -var-file=vars.tfvars -out=langfuse.tfplan
terraform apply "langfuse.tfplan"
```

## Variables

| Name                           | Description                                                    | Type     | Default                    | Required |
| ------------------------------ | -------------------------------------------------------------- | -------- | -------------------------- | :------: |
| langfuse_host                  | The hostname for Langfuse ingress (e.g., langfuse.example.com) | `string` | n/a                        |   yes    |
| admin_email                    | The email address for the initial admin user                   | `string` | n/a                        |   yes    |
| org_id                         | The organisation ID for Langfuse initialisation                | `string` | n/a                        |   yes    |
| org_name                       | The organisation name for Langfuse initialisation              | `string` | n/a                        |   yes    |
| project_id                     | The project ID for Langfuse initialisation                     | `string` | n/a                        |   yes    |
| project_name                   | The project name for Langfuse initialisation                   | `string` | n/a                        |   yes    |
| langfuse_namespace             | The Kubernetes namespace where Langfuse will be deployed       | `string` | `"langfuse"`               |    no    |
| chart_version                  | The version of the Langfuse Helm chart to deploy              | `string` | `"1.0.0"`                  |    no    |
| clickhouse_volume_size         | Storage size for ClickHouse persistent volume                  | `string` | `"50Gi"`                   |    no    |
| s3_volume_size                 | Storage size for S3/MinIO persistent volume                    | `string` | `"50Gi"`                   |    no    |
| ingress_class_name             | The Ingress class name to use for Langfuse ingress            | `string` | `"nginx"`                  |    no    |
| cert_manager_cluster_issuer    | The cert-manager ClusterIssuer to use for TLS certificates    | `string` | `"letsencrypt-production"` |    no    |

## Outputs

| Name                   | Description                                                  | Sensitive |
| ---------------------- | ------------------------------------------------------------ | --------- |
| langfuse_namespace     | The Kubernetes namespace where Langfuse is deployed          | no        |
| langfuse_url           | The URL where Langfuse UI is accessible                      | no        |
| langfuse_internal_url  | The internal Kubernetes service URL for Langfuse             | no        |
| public_key             | Langfuse project public key for SDK integration              | yes       |
| secret_key             | Langfuse project secret key for SDK integration              | yes       |
| instructions           | Instructions for retrieving credentials and accessing Langfuse | no        |

## Post-Deployment

### 1. Configure DNS

Point your domain to the Ingress controller's external IP:

```bash
# Get the external IP of your Ingress controller
kubectl get svc -n ingress-nginx

# Create an A record:
# langfuse.example.com -> <EXTERNAL_IP>
```

### 2. Retrieve Credentials

Use the provided kubectl commands to retrieve the admin credentials:

```bash
# Admin email
kubectl -n langfuse get secret langfuse-admin -o jsonpath="{.data.admin-email}" | base64 --decode

# Admin password
kubectl -n langfuse get secret langfuse-admin -o jsonpath="{.data.admin-password}" | base64 --decode
```

### 3. Access Langfuse UI

Navigate to `https://your-langfuse-host.com` and log in with the admin credentials.

### 4. Integrate with Your Application

Use the Langfuse SDK in your application:

```python
from langfuse import Langfuse

# Initialize with the credentials from Kubernetes secret
langfuse = Langfuse(
    public_key="<LANGFUSE_PUBLIC_KEY>",
    secret_key="<LANGFUSE_SECRET_KEY>",
    host="<LANGFUSE_HOST>"
)
```

## Architecture

The module deploys the following components:

- **Langfuse Web**: Next.js application (500m CPU, 1Gi memory)
- **PostgreSQL**: Primary database (Bitnami legacy image)
- **ClickHouse**: Analytics database (3 replicas, configurable storage)
  - **ZooKeeper**: Coordination service for ClickHouse (3 replicas)
- **Valkey**: Redis-compatible cache (250m CPU, 512Mi memory)
- **MinIO**: S3-compatible object storage (configurable storage)

All credentials are automatically generated and stored in a Kubernetes secret.

## Resource Requirements

Recommended minimum cluster resources:
- **CPU**: 4+ cores
- **Memory**: 8+ GB RAM
- **Storage**: Based on your `clickhouse_volume_size` and `s3_volume_size` settings

## Security

- Sign-up is disabled by default (only the admin user can create new accounts)
- All credentials are randomly generated (32 characters, alphanumeric)
- TLS certificates are automatically provisioned via cert-manager
- Credentials stored in Kubernetes secrets
- Internal service communication uses cluster DNS

## Notes

- This module uses Bitnami legacy images for compatibility
- The initial organisation and project are created automatically on first deployment
- Storage classes use "default" - ensure your cluster has a default storage class configured
- cert-manager must be installed separately (see [cert-manager module](../cert-manager))

## Troubleshooting

### Pod stuck in Pending state

Check if you have a default storage class:

```bash
kubectl get storageclass
```

### TLS certificate not issued

Verify cert-manager is installed and the ClusterIssuer exists:

```bash
kubectl get clusterissuer
kubectl get certificate -n langfuse
```

### Application not starting

Check pod logs:

```bash
kubectl logs -n langfuse -l app=langfuse-web
```

## References

- [Langfuse Documentation](https://langfuse.com/docs)
- [Langfuse Kubernetes Deployment](https://langfuse.com/docs/deployment/self-host)
- [Langfuse Helm Chart](https://github.com/langfuse/langfuse-k8s)
