# Architecture & Design Decisions

This document explains the architectural choices and design principles behind this GCP infrastructure repository.

## Core Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          GitHub Repository                       │
│                                                                     │
│  ┌─────────────────────┐    ┌────────────────────────────────┐  │
│  │  Terraform Configs  │    │  Kubernetes Manifests                │
│  │ (IaC - GCP Infra)   │    │  (GitOps - Flux v2)            │  │
│  └────────────┬────────┘    └────────────────┬─────────────────┘  │
│               │                               │                    │
│     ┌─────────▼──────────────────────────────▼────────────┐      │
│     │         GitHub Actions CI/CD Pipeline               │      │
│     │  - Terraform Plan & Validate                        │      │
│     │  - Security Scanning (Checkov, Trivy)               │      │
│     │  - Terraform Apply (on merge)                       │      │
│     └──────────────────────┬─────────────────────────────┘      │
│                            │                                     │
│                   ┌────────▼────────┐                            │
│                   │   GCP Project    │                            │
│                   └────────┬────────┘                            │
│                            │                                     │
└────────────────────────────┼──────────────────────────────────┘
                             │
        ┌────────────────────▼────────────────────┐
        │                                            │
        │    Private GKE Cluster                    │
        │    (VPC + Network Isolation)              │
        │                                            │
        │  ┌──────────────────────────────────┐   │
        │  │  Kubernetes Namespaces           │   │
        │  │  ┌────────────────────────────┐  │   │
        │  │  │ flux-system                │  │   │
        │  │  │ - Flux Controllers         │  │   │
        │  │  └────────────────────────────┘  │   │
        │  │  ┌────────────────────────────┐  │   │
        │  │  │ external-secrets           │  │   │
        │  │  │ - ESO Controllers          │  │   │
        │  │  │ - GCP Secret Manager sync  │  │   │
        │  │  └────────────────────────────┘  │   │
        │  │  ┌────────────────────────────┐  │   │
        │  │  │ ingress-nginx              │  │   │
        │  │  │ - Ingress Controller       │  │   │
        │  │  │ - Load Balancing           │  │   │
        │  │  └────────────────────────────┘  │   │
        │  │  ┌────────────────────────────┐  │   │
        │  │  │ applications               │  │   │
        │  │  │ - User Applications        │  │   │
        │  │  │ - Services & Deployments   │  │   │
        │  │  └────────────────────────────┘  │   │
        │  └──────────────────────────────────┘  │
        │                                         │
        │  Connected to:                          │
        │  - Cloud SQL PostgreSQL (private)       │
        │  - Cloud Memorystore Redis (private)    │
        │  - Secret Manager (via ESO)             │
        │  - Artifact Registry (via Flux)         │
        │  - Cloud Logging & Monitoring           │
        │                                         │
        └────────────────────────────────────────┘
```

## Design Principles

### 1. Security by Default

**Private by Default**
- GKE cluster has no public API endpoint
- All databases are in private subnets (Private Service Access)
- Managed services (Redis, Secret Manager) only accessible from VPC
- No public jumpbox (use IAP tunneling instead)

**Workload Identity Federation**
- Modern standard: Kubernetes → GCP IAM bindings
- No long-lived service account keys
- Fine-grained permissions per workload
- Simplified credential management

**Zero-Trust Access**
- Identity-Aware Proxy (IAP) for kubectl and SSH
- No static IP whitelist
- Authentication via gcloud/browser
- Audit trail of all access

### 2. Production-Grade Reliability

**High Availability**
- Multi-zone Cloud SQL with regional failover
- GKE cluster across multiple nodes
- Automatic node healing & upgrades
- Pod Disruption Budgets for graceful drains

**Disaster Recovery**
- Cloud SQL automated backups with PITR (7 days retention)
- Point-in-Time Recovery enabled
- Redis persistence with automatic snapshots
- Terraform state management (should use GCS backend)

**Observability**
- Cloud Logging for all components
- Cloud Monitoring with custom metrics
- GKE audit logging
- Query Insights for Cloud SQL performance

### 3. Infrastructure as Code (IaC)

**Modular Design**
- Each module handles single responsibility
- Modules are independently testable
- Reusable across environments
- Clear interfaces (inputs/outputs)

**Code Quality**
- Input validation with Terraform `validation` blocks
- Descriptive variable names and documentation
- No hardcoded values (use variables)
- DRY principle (Don't Repeat Yourself)

**Version Control**
- All infrastructure defined in Git
- Pull request workflow for changes
- Automated security scanning
- Terraform plan reviewed before apply

## Technology Choices & Rationale

### Why Google Cloud Platform?

- **Managed Services**: GKE, Cloud SQL, Redis are GCP-native
- **Integration**: Workload Identity, Secret Manager, IAM deeply integrated
- **Cost**: Generally competitive with AWS/Azure for Kubernetes
- **Community**: Strong GKE ecosystem and support

###  Why Private GKE over Autopilot?

**Standard GKE chosen for:**
- Full control over node machine types and scaling
- Custom node image options
- Lower cost for predictable workloads
- Compatibility with enterprise requirements

**Autopilot trade-offs:**
- More expensive (~$0.10/hour base)
- Less control over infrastructure
- Better for managing complexity (use if scaling to many clusters)

### Why Flux v2 over ArgoCD?

**Flux v2 advantages:**
- Native Kubernetes multi-tenancy (via namespaces)
- Lower resource overhead
- Simpler RBAC model
- CNCF-aligned architecture
- Better Helm v3 OCI support

**ArgoCD trade-offs:**
- Web UI for operations (Flux uses kubectl)
- Steeper learning curve (Flux is more native)
- More resource-hungry
- Better for multi-team governance (if needed, can use ApplicationSets)

### Why External Secrets Operator (ESO)?

**Advantages over mounting secrets:**
- Automatic rotation support
- Multi-secret aggregation
- Type conversion (mount as files or envvars)
- Audit trail in GCP Secret Manager
- Never store secrets in Git

**Alternative considered:**
- Sealed Secrets (local key management, more complex)
- Vault (external dependency, more operational overhead)
- Direct Secret Manager API (less Kubernetes-native)

### Why Terraform v1.7+?

- **Latest features**: Moved blocks, test mode, dynamic expressions
- **Better validation**: Input validation blocks
- **Performance**: Improved parallelism
- **Security**: Enhanced state locking

## Network Architecture

### CIDR Allocation

```
Primary VPC:        10.0.0.0/16
├─ GKE Nodes:       10.1.0.0/20    (4,094 IPs for ~1000 nodes)
└─ Secondary Ranges:
   ├─ Pods:         10.64.0.0/14   (262,144 IPs for ~65k pods)
   └─ Services:     10.68.0.0/14   (262,144 IPs for ~65k services)

Private IP Ranges (Reserved for databases):
├─ Cloud SQL:       10.240.0.0/24 (via Private Service Connection)
└─ Redis:           (same peering range as Cloud SQL)
```

**Rationale:**
- /16 provides growth capacity for multiple clusters
- /20 nodes subnet can handle 1000+ nodes
- /14 pod range supports ~65k pods per cluster
- /14 services range for VIP allocation
- Separate private ranges for managed services (no routing issues)

### Network Security

**Egress Control:**
- Cloud NAT for all outbound traffic
- Controlled via Cloud Router
- IP whitelist capability for external APIs

**Firewall Rules:**
- Deny-by-default ingress policy
- Allow internal VPC communication
- Allow IAP traffic (35.235.240.0/20)
- Restrict DNS (UDP/53) for name resolution

**Private Service Connect (PSC):**
- Eliminates routing complexity for managed services
- Replaces conventional VPC peering
- Reduces blast radius of compromised pods

## Workload Identity Federation

### How It Works

```
┌──────────────────┐
│  Kubernetes Pod  │
│  (demo-app-sa)   │
└────────┬─────────┘
         │
         │ Uses metadata service
         │ (iam.gke.io/gcp-service-account annotation)
         │
         ▼
┌──────────────────────────────────────────┐
│  GKE Metadata Server                      │
│  (provides ID token for K8s SA identity)  │
└────────┬─────────────────────────────────┘
         │
         │ Exchanges ID token for GCP credentials
         │ (via gcloud SDK)
         │
         ▼
┌──────────────────────────────────────────┐
│  GCP IAM                                  │
│  (validates K8s SA → GCP SA binding)      │
│  (Workload Identity Pool: project.svc.id)│
└────────┬─────────────────────────────────┘
         │
         │ Returns short-lived GCP credentials
         │
         ▼
┌──────────────────┐
│  Pod Access      │
│  GCP Resources   │
│  (Cloud SQL,     │
│   Secret Manager,│
│   Cloud Storage) │
└──────────────────┘
```

**Setup:**
1. Create GCP Service Account (e.g., `demo-app-sa`)
2. Bind K8s SA to GCP SA: `demo-app-sa/demo-app@PROJECT_ID.svc.id.goog`
3. Grant IAM role to GCP SA (e.g., `roles/cloudsql.client`)
4. Annotate K8s SA: `iam.gke.io/gcp-service-account: demo-app-sa@PROJECT_ID.iam.gserviceaccount.com`
5. Pod automatically gets credentials via metadata service

**Benefits:**
- ✅ No key sharing or rotation
- ✅ Automatic credentials (GCLOUD_APPLICATION_CREDENTIALS)
- ✅ Audit trail in GCP Cloud Audit Logs
- ✅ Fine-grained permissions per pod
- ✅ Easy secret rotation (GCP side only)

## GitOps Workflow

### How Flux Syncs Infrastructure

```
1. Developer pushes to GitHub
   └─> Commits to /gitops/applications/myapp.yaml

2. Flux detects changes (polls every 10m)
   └─> GitRepository controller fetches latest commits

3. Reconciliation runs
   └─> Kustomization controller applies manifests

4. Kubernetes resources created/updated
   └─> Pods deployed, services updated, etc.

5. Flux continuously monitors
   └─> If manual changes detected, corrects them (GitOps principle)
```

### Why Flux Instead of Manual kubectl apply?

- **Declarative**: Kubernetes state in Git (source of truth)
- **Auditable**: All changes tracked via Git history
- **Automatic**: Flux continuously reconciles cluster to Git state
- **Idempotent**: Safe to run multiple times
- **Error Recovery**: Automatic retry and healing

## External Secrets Operator (ESO) Flow

```
┌────────────────────────────┐
│  Developer creates secret   │
│  in GCP Secret Manager      │
│  (gcloud secrets create)    │
└────────────┬────────────────┘
             │
             ▼
┌────────────────────────────┐
│  ExternalSecret in K8s     │
│  (references Secret Manager│
│   secret name)             │
└────────────┬────────────────┘
             │
             ▼
┌────────────────────────────┐
│  ESO Controller            │
│  (validates permissions    │
│   via Workload Identity)   │
└────────────┬────────────────┘
             │
             ▼
┌────────────────────────────┐
│  Fetched from Secret Mgr   │
│  (Workload Identity used   │
│   for auth)                │
└────────────┬────────────────┘
             │
             ▼
┌────────────────────────────┐
│  Kubernetes Secret Created │
│  (in target namespace)     │
│                            │
│  Applications mount as:    │
│  - Environment variables   │
│  - Mounted files           │
│  - Volume projections      │
└────────────────────────────┘
```

**Security Property:** Secrets never stored in Git, only in GCP Secret Manager with encrypted state in Kubernetes.

## Cost Optimization Strategies

### Resource Sizing

| Component | Dev | Staging | Production |
|-----------|-----|---------|------------|
| **GKE** | 1 node (e2-medium) | 2 nodes (n1-standard-2) | 3 nodes (n2-standard-4) |
| **Cloud SQL** | f1-micro (2GB) | f1-micro (10GB) | db-n1-highmem-2 (100GB) |
| **Redis** | 1GB | 2GB | 5GB |
| **Networking** | Shared NAT | Dedicated NAT | Multi-region NAT |

### Cost Reduction Options

1. **Use Preemptible VMs**
```hcl
preemptible = true  # 70% discount, but can be evicted
```

2. **Committed Use Discounts (CUDs)**
- 1-year or 3-year purchases
- 25-30% discount

3. **Horizontal Pod Autoscaling**
```yaml
minReplicas: 1
maxReplicas: 3
targetCPUUtilization: 70%
```

4. **Vertical Pod Autoscaling**
- Right-size resource requests

5. **Reserved IPs for NAT**
- Only pay for actual egress traffic

## Scaling Considerations

### Adding New Clusters

To add additional environments (staging, development):

```
infrastructure/gcp/
├── modules/          # Shared modules
└── environments/
    ├── base/         # Production
    ├── staging/      # Copy and modify
    └── development/  # Copy and modify
```

### Multi-Team / Multi-Tenancy

For organizations with multiple teams:

1. Create separate GKE clusters per team
2. Use Flux with different Git repos per team
3. Separate GCP projects per team (recommended)
4. Cross-cluster service discovery via Istio/Linkerd

## Security Hardening Checklist

- ✅ Private GKE cluster (no public endpoint)
- ✅ Workload Identity Federation (no keys)
- ✅ Binary Authorization enabled
- ✅ GKE network policies enforced
- ✅ RBAC and Pod Security Standards
- ✅ Private Cloud SQL (Private Service Access)
- ✅ Encrypted secrets (Secret Manager)
- ✅ VPC firewall rules (default deny)
- ✅ Cloud Audit Logging enabled
- ✅ Cloud Monitoring for anomaly detection

## Future Enhancements

- **Service Mesh**: Istio/Linkerd for advanced traffic management
- **Policy as Code**: OPA/Gatekeeper for admission control
- **Multi-Region**: Cross-region failover and load balancing
- **Backup**: Automated Kubernetes backup (Velero)
- **DRR (Disaster Recovery)**: Automated failover procedures

---

**Document Version:** 1.0
**Last Updated:** March 26, 2026
**Architecture Stability:** Production-Ready
