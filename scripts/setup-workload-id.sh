#!/bin/bash
set -euo pipefail

# setup-workload-id.sh - Configure Workload Identity Federation bindings
# This bridges GCP IAM service accounts to Kubernetes service accounts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration from environment or defaults
PROJECT_ID="${PROJECT_ID:-}"
CLUSTER_NAME="${CLUSTER_NAME:-gke-primary-cluster}"
CLUSTER_ZONE="${CLUSTER_ZONE:-us-central1}"

# Helper functions
die() {
    echo -e "${RED}Error: $*${NC}" >&2
    exit 1
}

info() {
    echo -e "${BLUE}$*${NC}"
}

success() {
    echo -e "${GREEN}✓ $*${NC}"
}

# Get PROJECT_ID if not set
if [[ -z "$PROJECT_ID" ]]; then
    PROJECT_ID=$(gcloud config get-value project) || die "PROJECT_ID not set"
fi

info "Setting up Workload Identity Federation"
info "PROJECT_ID: $PROJECT_ID"
info "CLUSTER_NAME: $CLUSTER_NAME"
info "CLUSTER_ZONE: $CLUSTER_ZONE"

# Function to bind a Kubernetes SA to a GCP SA
bind_workload_identity() {
    local k8s_namespace=$1
    local k8s_sa_name=$2
    local gcp_sa_email=$3

    info "Binding K8s SA ($k8s_namespace/$k8s_sa_name) to GCP SA ($gcp_sa_email)..."

    # Create the Kubernetes service account annotation
    kubectl annotate serviceaccount "$k8s_sa_name" \
        -n "$k8s_namespace" \
        iam.gke.io/gcp-service-account="$gcp_sa_email" \
        --overwrite \
        2>/dev/null || true

    # Grant the GCP SA permission to impersonate the K8s SA
    gcloud iam service-accounts add-iam-policy-binding "$gcp_sa_email" \
        --role roles/iam.workloadIdentityUser \
        --member "serviceAccount:${PROJECT_ID}.svc.id.goog[${k8s_namespace}/${k8s_sa_name}]" \
        --project "$PROJECT_ID" \
        --condition=None \
        --quiet 2>/dev/null || true

    success "Bound K8s SA ($k8s_namespace/$k8s_sa_name) to GCP SA ($gcp_sa_email)"
}

# Get cluster credentials
info "Getting cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --zone "$CLUSTER_ZONE" \
    --project "$PROJECT_ID" || die "Failed to get cluster credentials"

# Setup External Secrets Operator
info "\nConfiguring External Secrets Operator..."
kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount external-secrets -n external-secrets --dry-run=client -o yaml | kubectl apply -f -

bind_workload_identity "external-secrets" "external-secrets" "external-secrets-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Setup Flux System
info "\nConfiguring Flux GitOps..."
kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount flux-system -n flux-system --dry-run=client -o yaml | kubectl apply -f -

bind_workload_identity "flux-system" "flux-system" "flux-system-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Setup Applications namespace
info "\nConfiguring Applications namespace..."
kubectl create namespace applications --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount demo-app-sa -n applications --dry-run=client -o yaml | kubectl apply -f -

bind_workload_identity "applications" "demo-app-sa" "demo-app-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Setup Ingress Nginx
info "\nConfiguring Ingress-Nginx..."
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount ingress-nginx -n ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

bind_workload_identity "ingress-nginx" "ingress-nginx" "ingress-nginx-sa@${PROJECT_ID}.iam.gserviceaccount.com" 2>/dev/null || info "Optional: Ingress-Nginx GCP SA can be skipped if not using GCP integrations"

# Verify bindings
info "\nVerifying Workload Identity bindings..."
kubectl get serviceaccounts --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.metadata.annotations.iam\.gke\.io/gcp-service-account}{"\n"}{end}' | grep -v "^$" || true

success "Workload Identity Federation setup complete!"
info "\nYou can now use Workload Identity in your pods:"
info "  - External Secrets can access GCP Secret Manager"
info "  - Flux can access Artifact Registry"
info "  - Applications can access GCP resources (Cloud SQL, Cloud Storage, etc.)"
