# Dify Kubernetes Deployment

This repository contains Terraform configurations for deploying Dify.AI on Kubernetes. Dify is an LLM (Large Language Model) application development platform that provides out-of-the-box solutions for building AI applications.

## Architecture

The deployment consists of the following components:

- **API Service**: Main application backend (dify-api)
- **Web Interface**: Frontend application (dify-web)
- **Worker**: Background task processor (dify-worker)
- **Database**: PostgreSQL database (dify-postgres)
- **Cache**: Redis instance (dify-redis)
- **Vector Store**: Weaviate for vector storage (dify-weaviate)
- **Sandbox**: Isolated environment for code execution (dify-sandbox)
- **SSRF Proxy**: Squid proxy for secure external requests (dify-ssrf)
- **Nginx**: Reverse proxy and load balancer (dify-nginx)

## Prerequisites

- Kubernetes cluster
- Terraform v1.0+
- kubectl configured to access your cluster
- Domain name for ingress configuration
- NGINX Ingress Controller installed in the cluster
- GitLab account for CI/CD and state management

## Environment Variables

The following environment variables need to be set:

```bash
# Kubernetes Configuration
export TF_VAR_KUBECONFIG_MKS8="path/to/your/kubeconfig"

# Database Credentials
export TF_VAR_PG_USERNAME="postgres"
export TF_VAR_PG_PASSWORD="your-secure-password"
export TF_VAR_PG_DATABASE="dify"

# Redis Credentials
export TF_VAR_REDIS_USERNAME=""  # Optional
export TF_VAR_REDIS_PASSWORD="your-secure-password"

# Weaviate Configuration
export TF_VAR_WEAVIATE_API_KEY="your-weaviate-api-key"

# Dify Configuration
export TF_VAR_SECRET_KEY="your-dify-secret-key"
export TF_VAR_DOMAIN="your-domain.com"
export TF_VAR_STORAGE_PATH="/path/to/storage"
export TF_VAR_IMAGE_TAG="1.1.3"

# GitLab CI/CD Variables
export TF_VAR_GITLAB_USERNAME="your-gitlab-username"
export TF_VAR_GITLAB_TOKEN="your-gitlab-token"
```

## Project Structure

```
.
├── terraform/
│   ├── api.tf          # API service configuration
│   ├── web.tf          # Web frontend configuration
│   ├── worker.tf       # Background worker configuration
│   ├── postgres.tf     # PostgreSQL database configuration
│   ├── redis.tf        # Redis cache configuration
│   ├── weaviate.tf     # Vector store configuration
│   ├── sandbox.tf      # Code sandbox configuration
│   ├── ssrf.tf         # SSRF proxy configuration
│   ├── nginx.tf        # Nginx reverse proxy configuration
│   ├── ingress.tf      # Ingress rules
│   ├── secrets.tf      # Kubernetes secrets
│   ├── variables.tf    # Variable definitions
│   └── outputs.tf      # Output definitions
└── .gitlab-ci.yml      # GitLab CI/CD configuration
```

## Configuration

### Variables

All sensitive configuration is managed through environment variables with the `TF_VAR_` prefix. This includes:

- Database credentials
- Redis credentials
- API keys
- Secret keys
- Domain configuration
- Storage paths

### Security Note

Never commit sensitive credentials to version control. Always use environment variables or secure secret management solutions in production environments.

## Deployment

### Using GitLab CI/CD

1. Fork/clone this repository to your GitLab account
2. Configure the following CI/CD variables in your GitLab project settings:
   - All environment variables listed above with `TF_VAR_` prefix
   - Ensure variables containing sensitive data are marked as "Protected" and "Masked"

The pipeline will automatically:
1. Plan the Terraform changes using the provided variables
2. Apply the configuration to your cluster

### Manual Deployment

1. Set all required environment variables:
```bash
source ./set-env.sh  # Create this file with your environment variables
```

2. Initialize Terraform:
```bash
cd terraform
terraform init
```

3. Review the deployment plan:
```bash
terraform plan
```

4. Apply the configuration:
```bash
terraform apply
```

## Access URLs

After successful deployment, the following URLs will be available:

- Web Interface: `https://dify.<domain>`
- API: `https://difyapi.<domain>`
- Console API: `https://consoleapi.<domain>`
- App Interface: `https://difyapp.<domain>`
- App API: `https://appapi.<domain>`

## Storage

The deployment uses host path volumes for persistence:

- PostgreSQL: `/root/dify/db/postgres/data`
- Redis: `/root/dify/db/redis/data`
- Weaviate: `/root/dify/db/weaviate/data`
- API Storage: `/root/dify/app/api/storage`

## Security Features

- All sensitive configuration managed through environment variables
- CORS configuration through ConfigMap
- TLS termination at ingress level
- Secrets management through Kubernetes secrets
- SSRF protection via Squid proxy
- Service isolation through Kubernetes namespaces
- Resource limits and requests for all containers

## Maintenance

### Scaling

Services can be scaled by adjusting the `replicas` parameter in the respective StatefulSet/Deployment resources.

### Upgrades

To upgrade Dify components:

1. Update the `image_tag` variable
2. Run `terraform plan` to review changes
3. Apply the changes with `terraform apply`

### Backup

Ensure regular backups of:
- PostgreSQL data
- Redis data
- Weaviate data
- API storage files

## Troubleshooting

Common issues and solutions:

1. **Environment Variables**
   ```bash
   # Verify environment variables are set
   env | grep TF_VAR_
   ```

2. **Pod Startup Issues**
   ```bash
   kubectl logs -n dify <pod-name>
   kubectl describe pod -n dify <pod-name>
   ```

3. **Database Connection Issues**
   - Verify environment variables for database credentials
   - Check PostgreSQL pod status
   ```bash
   kubectl get pods -n dify | grep postgres
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Merge Request

## License

This project is licensed under the MIT License.

## Project Status

Active development and maintenance.

For support or questions, please open an issue in the GitLab repository.
