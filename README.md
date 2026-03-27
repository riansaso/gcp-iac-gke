# GCP Infrastructure as Code - GKE Private Cluster

Production-ready, SOTA (State-of-the-Art) infrastructure repository for Google Cloud Platform with private GKE clusters, managed databases, and GitOps workflows.

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                     │
│  📊 Architecture Overview (us-central1 Region)                      │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │                        VPC Network (10.0.0.0/16)         │     │
│  │                                                          │     │
│  │  ┌────────────────────────────────────────────────┐    │     │
│  │  │  Private GKE Standard Cluster                   │    │     │
│  │  │  - Workload Identity Federation                │    │     │
│  │  │  - GKE Dataplane V2 (eBPF)                      │    │     │
│  │  │  - Binary Authorization Enabled                │    │     │
│  │  │  - No Public Endpoint (IAP only)                │    │     │
│  │  │                                                  │    │     │
│  │  │  Pods: 10.64.0.0/14                             │    │     │
│  │  │  Services: 10.68.0.0/14                         │    │     │
│  │  │  Nodes: 10.1.0.0/20                             │    │     │
│  │  └────────────────────────────────────────────────┘    │     │
│  │                                                          │     │
│  │  ┌──────────────────┐  ┌──────────────────────────┐    │     │
│  │  │ Cloud SQL        │  │ Cloud Memorystore Redis  │    │     │
│  │  │ PostgreSQL v15+  │  │ v7+ with PSC             │    │     │
│  │  │ Private Access   │  │ Private Connection       │    │     │
│  │  │ IAM Auth         │  │                          │    │     │
│  │  └──────────────────┘  └──────────────────────────┘    │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  Managed Services                                        │     │
│  │  • Artifact Registry (Docker & Helm OCI)                │     │
│  │  • Secret Manager (Encrypted at rest)                   │     │
│  │  • Cloud Logging & Monitoring                           │     │
│  │  • Cloud NAT + Cloud Router (Egress control)            │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                     │
│  🔐 Access: IAP Tunnels (No Public Jumpbox)                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────┘
```

## Features

✅ **Private & Secure by Default**
- Private GKE cluster (no public endpoint)
- Workload Identity Federation (modern zero-trust)
- Binary Authorization enforcement
- IAP tunnels for kubectl/SSH access
- Private Service Connection (PSC) for all managed services

✅ **Production-Grade Infrastructure**
- Terraform v1.7+ with modular architecture
- Advanced validation blocks and input validation
- High-availability Cloud SQL with PITR backups
- Cloud Memorystore Redis with automatic failover
- GKE Dataplane V2 (eBPF-based networking)

✅ **GitOps & Container Registry**
- Flux v2 for declarative Kubernetes management
- External Secrets Operator (ESO) → GCP Secret Manager
- Artifact Registry (Docker + Helm OCI repositories)
- Ingress-Nginx with load balancing

✅ **CI/CD & Automation**
- GitHub Actions with reusable workflows
- Terraform security scanning (Checkov)
- IaC scanning with Trivy
- Taskfile orchestration for local development

✅ **Observability**
- Cloud Logging integration
- Cloud Monitoring with custom dashboards
- GKE audit logging
- Query Insights for Cloud SQL

## Prerequisites

- **GCP Account** with billing enabled
- **Google Cloud SDK** (`gcloud`) - v450+
- **Terraform** - v1.7+
- **kubectl** - v1.27+
- **Helm** - v3+
- **Task** (Taskfile runner) - v3+
- **Git** - for repository cloning
- **Docker** - (optional, for local container testing)

## Quick Start

### 1. Clone Repository & Setup Environment

```bash
git clone https://github.com/riansaso/gcp-iac-gke.git
cd gcp-iac-gke

# Export required variables
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"

# Create .env.local for Taskfile
cat > .env.local << EOF
export PROJECT_ID=$PROJECT_ID
export REGION=$REGION
EOF
```

### 2. Validate Environment

```bash
task validate-env
```

This checks:
- ✅ gcloud, terraform, kubectl, helm, task installed
- ✅ GCP authentication & project configuration
- ✅ IAM permissions (informational)
- ✅ kubeconfig setup

### 3. Update Configuration

Edit `infrastructure/gcp/environments/base/terraform.tfvars`:

```hcl
project_id           = "YOUR_PROJECT_ID"  # REQUIRED
region               = "us-central1"
gke_min_nodes        = 3
gke_max_nodes        = 10
postgres_disk_size_gb = 10
redis_memory_size_gb = 1
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
task tf:init

# Plan changes
task tf:plan

# Apply changes (requires manual approval in CI/CD)
task tf:apply
```

**Time estimate:** 15-25 minutes (GKE cluster creation is the bottleneck)

### 5. Setup GitOps & Workload Identity

```bash
# Get cluster credentials
task k8s:get-credentials

# Setup Flux & ESO with Workload Identity bindings
task k8s:flux-setup

# Verify deployment
task k8s:check-pods
```

### 6. Verify Cluster

```bash
# List nodes
task k8s:check-nodes

# List pods across all namespaces
task k8s:check-pods

# View Flux logs
task k8s:logs-flux
```

## Taskfile Commands

### Infrastructure Management

```bash
task tf:init        # Initialize Terraform
task tf:validate    # Validate configuration
task tf:plan        # Plan changes
task tf:apply       # Apply changes
task tf:destroy     # Destroy infrastructure (DESTRUCTIVE)
task tf:output      # Show outputs
```

### Kubernetes Operations

```bash
task k8s:get-credentials   # Fetch cluster credentials
task k8s:flux-setup        # Install Flux v2 + ESO
task k8s:check-nodes       # Show cluster nodes
task k8s:check-pods        # Show all pods
task k8s:logs-flux         # Tail Flux logs
task k8s:logs-eso          # Tail ESO logs
task k8s:apply-demo-app    # Deploy demo application
```

### GCP Operations

```bash
task gcp:enable-apis       # Enable required APIs
task gcp:list-clusters     # List GKE clusters
task gcp:list-databases    # List Cloud SQL instances
task gcp:list-redis        # List Redis instances
task gcp:account-info      # Show account details
task gcp:create-secret     # Create secret in GCP Secret Manager
```

### Complete Setup

```bash
task setup  # validate-env → terraform:apply → kubernetes:flux-setup
```

## Secrets Management

Secrets are **never committed to Git**. Use GCP Secret Manager + External Secrets Operator:

### Create a Secret

```bash
task gcp:create-secret
# Or with arguments:
./scripts/create-secret.sh --name my-secret --value "secret-content"
```

### Sync Secret to Kubernetes

Create an `ExternalSecret` in your application namespace:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secrets
  namespace: applications
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: gcp-secrets
    kind: SecretStore
  target:
    name: my-app-secrets
    creationPolicy: Owner
  data:
  - secretKey: db-password
    remoteRef:
      key: my-secret  # GCP Secret Manager secret name
```

External Secrets Operator will automatically sync the secret.

## Deploying Applications

### Option 1: GitOps with Flux

Place application manifests in `/gitops/applications/` and commit to the repository. Flux will automatically detect and apply changes.

### Option 2: Direct kubectl

```bash
kubectl apply -f my-app-manifests.yaml
```

## IAP Tunneling (Private Cluster Access)

For private GKE clusters (no public API endpoint):

```bash
# Setup IAP tunnel to kubectl API
./scripts/tunnel.sh kubectl --cluster-name gke-primary-cluster

# SSH into bastion instance via IAP
./scripts/tunnel.sh ssh --bastion gke-bastion --local-port 2222
```

## Required IAM Roles

The deploying service account needs these roles:

- `roles/compute.admin` - VPC, firewall, Cloud NAT, Cloud Router
- `roles/container.admin` - GKE cluster creation & management
- `roles/iam.securityAdmin` - Service accounts & IAM bindings
- `roles/secretmanager.admin` - GCP Secret Manager
- `roles/artifactregistry.admin` - Artifact Registry repositories
- `roles/cloudsql.admin` - Cloud SQL provisioning
- `roles/servicenetworking.admin` - Private Service Access

## GitHub Actions Setup

To use GitHub Actions for automation:

1. **Create Workload Identity Federation (WIF):**

```bash
gcloud iam workload-identity-pools create github \
  --project="$PROJECT_ID" \
  --location="global" \
  --display-name="GitHub"

# Get the pool resource name and create OIDC provider...
```

2. **Configure repository secrets:**

```
GCP_PROJECT_ID         - Your GCP project ID
WIF_PROVIDER           - Workload Identity pool provider
WIF_SERVICE_ACCOUNT    - Service account email
```

3. **Workflows trigger automatically on:**
   - Pull requests: `terraform plan` + security scanning
   - Merges to main: `terraform apply`

## Cost Optimization

This configuration is production-grade but includes costs:

- **GKE Standard:** ~$0.10/hour (3 nodes × n2-standard-4)
- **Cloud SQL:** ~$0.07/hour (db-f1-micro, SSD storage additional)
- **Redis:** ~$0.10/hour (1GB)
- **Networking:** Egress charges, NAT gateway IPs

**Estimated monthly cost:** $100-200

To reduce costs:
- Use `db-f1-micro` (low traffic testing)
- Reduce node count or use preemptible VMs
- Use `STANDARD` tier Redis instead of `PREMIUM`

## Troubleshooting

### GKE cluster stuck in PROVISIONING

```bash
# Check cluster status
gcloud container clusters describe gke-primary-cluster --zone us-central1

# Check operations
gcloud container operations list
```

### Flux not syncing repositories

```bash
# Check Flux logs
task k8s:logs-flux

# Force sync
kubectl -n flux-system rollout restart deployment flux-controller
```

### External Secrets not syncing

```bash
# Check ESO logs
task k8s:logs-eso

# Verify Secret Manager permissions
gcloud secrets get-iam-policy my-secret
```

### Private Cloud SQL connection issues

```bash
# Test Cloud SQL Proxy connection
cloud_sql_proxy \
  -instances=PROJECT_ID:REGION:INSTANCE_NAME \
  -ip_address_types=PRIVATE
```

## Directory Structure

```
.
├── Taskfile.yml                    # Root task orchestration
├── .github/workflows/              # GitHub Actions CI/CD
├── infrastructure/gcp/
│   ├── modules/                    # Terraform modules (networking, GKE, IAM, etc.)
│   └── environments/base/          # Base environment composition
├── gitops/
│   ├── infrastructure/             # Flux, ESO, Ingress-Nginx
│   └── applications/               # Application deployments
├── scripts/                        # Operational scripts
├── tasks/                          # Taskfile includes
└── docs/                           # Additional documentation
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make changes and test locally (`task validate-env && task tf:plan`)
4. Commit with descriptive messages
5. Open a pull request (triggers `terraform plan` automatically)

## Security Considerations

- ✅ Secrets never committed to Git (use External Secrets Operator)
- ✅ Private GKE clusters (no public API endpoint)
- ✅ Workload Identity Federation (no service account keys)
- ✅ Binary Authorization (only verified images allowed)
- ✅ IAP tunneling (zero-trust access model)
- ✅ Encrypted secrets at rest (GCP Secret Manager)
- ✅ VPC isolation & firewall rules
- ✅ Cloud SQL IAM authentication
- ✅ RBAC and network policies on Kubernetes

## Support & Documentation

- 📖 [GCP Terraform Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- 📖 [Flux v2 Documentation](https://fluxcd.io/docs/)
- 📖 [External Secrets Operator Docs](https://external-secrets.io/)
- 📖 [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)

## License

MIT License - See LICENSE file

---

**Generated:** March 26, 2026
**Terraform Version:** v1.7+
**GCP Provider:** v5.x+
**Kubernetes:** 1.27+
