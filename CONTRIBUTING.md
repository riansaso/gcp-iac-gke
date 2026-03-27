# Contributing to GCP Infrastructure Repository

Thank you for your interest in contributing! Please follow these guidelines.

## Development Workflow

### 1. Prerequisites

- GCP Account with appropriate IAM roles
- All tools installed (see README.md prerequisites)
- Terraform v1.7+ and Google Provider v5.x+
- git configured with your identity

### 2. Setup Local Development

```bash
# Clone the repository
git clone https://github.com/riansaso/gcp-iac-gke.git
cd gcp-iac-gke

# Create feature branch
git checkout -b feature/your-feature-name

# Copy environment template
cp .env.example .env.local
# Edit .env.local with your project details
```

### 3. Make Changes

Follow these principles:

**Code Quality**
- Run `task fmt` to format all files
- Run `task tf:validate` to validate Terraform
- Keep configurations DRY (Don't Repeat Yourself)
- Use meaningful variable names

**Security**
- Never commit secrets (use GCP Secret Manager)
- Always use private endpoints when possible
- Enable encryption for all data at rest
- Use Workload Identity Federation, not service account keys
- Apply principle of least privilege to IAM roles

**Modularity**
- Keep modules focused on single responsibility
- Use outputs.tf to expose module interfaces
- Validate all inputs in variables.tf
- Document complex logic with comments

### 4. Test Changes Locally

```bash
# Validate syntax
task tf:validate

# Check formatting
task fmt

# Plan changes (dry-run)
task tf:plan

# Review the generated plan thoroughly before applying
```

### 5. Commit Changes

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: add feature name

Detailed description of what changed and why.

- Benefit 1
- Benefit 2"
```

**Commit Message Format:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `refactor:` - Code refactoring
- `test:` - Test additions
- `chore:` - Build, CI/CD, dependencies
- `security:` - Security improvements

**Examples:**
```
feat: add Redis caching layer
fix: correct VPC CIDR overlap in staging
docs: add troubleshooting guide
security: enforce TLS 1.2 minimum on Cloud SQL
```

### 6. Open Pull Request

```bash
git push origin feature/your-feature-name
```

Then open a PR on GitHub:

- **Title:** Brief description (e.g., "Add Redis cluster module")
- **Description:**
  - What problem does this solve?
  - How does it work?
  - Any breaking changes?
- **Checklist:**
  - [ ] Tested locally with `task tf:plan`
  - [ ] No secrets committed
  - [ ] Terraform formatted (`task fmt`)
  - [ ] Variables validated
  - [ ] Documentation updated

### 7. Code Review & Merge

- Address reviewer feedback
- GitHub Actions will automatically run:
  - Terraform formatting check
  - Terraform validation
  - Checkov security scanning
  - Trivy IaC scanning
- Once approved, merge to main (this triggers `terraform apply`)

## Module Development Guidelines

### Adding a New Module

1. Create module directory:
```bash
mkdir -p infrastructure/gcp/modules/new-module
```

2. Create required files:
```
infrastructure/gcp/modules/new-module/
├── main.tf          # Resource definitions
├── variables.tf     # Input variables with validation
└── outputs.tf       # Output values for other modules
```

3. Add input validation:
```hcl
variable "instance_name" {
  type        = string
  description = "Name of the resource"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,63}$", var.instance_name))
    error_message = "Must be 1-63 chars, lowercase, numbers, hyphens."
  }
}
```

4. Document outputs:
```hcl
output "instance_id" {
  value       = google_resource.main.id
  description = "Unique identifier of the resource"
}
```

5. Reference in environment composition:
```hcl
module "new_module" {
  source = "../modules/new-module"

  project_id = var.project_id
  region     = var.region
  # ... variables
}
```

## Kubernetes Manifestation Guidelines

For files in `/gitops/`:

1. **Namespace Separation**
   - System components in dedicated namespaces (`flux-system`, `external-secrets`)
   - Applications in `applications` namespace
   - Each app in its own namespace if scaling to multiple teams

2. **Use Workload Identity Annotations**
```yaml
metadata:
  annotations:
    iam.gke.io/gcp-service-account: app-sa@PROJECT_ID.iam.gserviceaccount.com
spec:
  serviceAccountName: app-workload-identity  # K8s SA name
```

3. **Resource Requests/Limits**
```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 512Mi
```

4. **Liveness & Readiness Probes**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Testing Changes

### Local Testing

```bash
# Test infrastructure plan
task tf:plan

# Validate Kubernetes manifests
kubectl apply -f gitops/applications/demo-app.yaml --dry-run=client -o yaml

# Check Helm chart syntax (if adding Helm)
helm template my-chart gitops/helm/my-chart
```

### CI/CD Testing

GitHub Actions will automatically:
1. Run `terraform fmt -check` (formatting)
2. Run `terraform validate` (syntax)
3. Run `checkov` (security policies)
4. Generate `terraform plan` (show impact)
5. Comment plan on PR

## Reporting Issues

Found a bug? Please open an issue with:

1. **Title:** Clear, concise description
2. **Description:**
   - What were you doing?
   - What happened?
   - What did you expect?
3. **Environment:**
   - GCP region
   - Terraform version
   - Provider versions
4. **Logs/Output:** Include relevant error messages

Example:
```markdown
## Bug Report

GKE cluster creation fails with quota error

### Steps to Reproduce
1. Run `task tf:apply`
2. Wait for GKE module to execute

### Expected Behavior
Cluster created successfully

### Actual Behavior
Error: `QUOTA_EXCEEDED: Quota 'CPUS' exceeded`

### Environment
- Region: us-central1
- Terraform: 1.7.2
- Provider: google 5.15.0
```

## Code Review Checklist

When reviewing PRs, check:

- ✅ **Security**: No secrets committed, proper IAM, encryption enabled
- ✅ **Quality**: Code formatted, validated, documented
- ✅ **Functionality**: Does it solve the stated problem?
- ✅ **Testing**: Changes tested locally (`task tf:plan`)
- ✅ **Compatibility**: No breaking changes without migration guide
- ✅ **Documentation**: README/docs updated if needed
- ✅ **Coverage**: All affected modules/components addressed

## Community

- **Ask questions:** Open a discussion or issue
- **Share ideas:** Propose features via issues
- **Help others:** Review PRs and answer questions

Thank you for contributing! 🙏
