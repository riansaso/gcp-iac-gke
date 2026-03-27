#!/bin/bash
set -euo pipefail

# create-secret.sh - Safe creation of secrets in GCP Secret Manager
# Prevents accidental plaintext secret commits to Git

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_ID="${PROJECT_ID:-}"

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

usage() {
    cat << EOF
usage: create-secret.sh --name SECRET_NAME [--value SECRET_VALUE] [--file FILE]

Creates a secret in GCP Secret Manager with encryption at rest.

OPTIONS:
  --name NAME         - Secret name in GCP Secret Manager (required)
  --value VALUE       - Secret value (optional, will be prompted if not provided)
  --file FILE         - Read secret from file instead of stdin/argument
  --project-id ID     - GCP project ID (default: from gcloud config)
  --help              - Show this help

EXAMPLES:
  # Prompt for secret value
  ./create-secret.sh --name database-password

  # Provide secret value as argument
  ./create-secret.sh --name api-key --value "your-secret-key"

  # Read secret from file
  ./create-secret.sh --name ssl-cert --file ./cert.pem
EOF
}

# Parse arguments
SECRET_NAME=""
SECRET_VALUE=""
SECRET_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            SECRET_NAME="$2"
            shift 2
            ;;
        --value)
            SECRET_VALUE="$2"
            shift 2
            ;;
        --file)
            SECRET_FILE="$2"
            shift 2
            ;;
        --project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

# Validate required arguments
[[ -n "$SECRET_NAME" ]] || die "Secret name is required (--name)"

# Get PROJECT_ID if not set
if [[ -z "$PROJECT_ID" ]]; then
    PROJECT_ID=$(gcloud config get-value project) || die "PROJECT_ID not set"
fi

info "Creating secret in GCP Secret Manager"
info "Project: $PROJECT_ID"
info "Secret name: $SECRET_NAME"

# Get secret value
if [[ -n "$SECRET_FILE" ]]; then
    if [[ ! -f "$SECRET_FILE" ]]; then
        die "File not found: $SECRET_FILE"
    fi
    info "Reading secret from file: $SECRET_FILE"
    SECRET_VALUE=$(cat "$SECRET_FILE")
elif [[ -z "$SECRET_VALUE" ]]; then
    info "Enter secret value (input will be hidden):"
    read -s -p "Secret value: " SECRET_VALUE || die "Failed to read secret"
    echo
fi

if [[ -z "$SECRET_VALUE" ]]; then
    die "Secret value cannot be empty"
fi

# Create secret in GCP Secret Manager
info "Creating secret in Secret Manager..."
echo -n "$SECRET_VALUE" | gcloud secrets create "$SECRET_NAME" \
    --data-file=- \
    --project "$PROJECT_ID" \
    --replication-policy="automatic" \
    2>&1 || {
    # If secret already exists, create a new version
    if gcloud secrets describe "$SECRET_NAME" --project "$PROJECT_ID" &>/dev/null; then
        info "Secret already exists, creating new version..."
        echo -n "$SECRET_VALUE" | gcloud secrets versions add "$SECRET_NAME" \
            --data-file=- \
            --project "$PROJECT_ID"
    else
        die "Failed to create secret"
    fi
}

success "Secret created/updated successfully!"
info "Secret name: $SECRET_NAME"
info "Project ID: $PROJECT_ID"
info "\nTo access this secret from Kubernetes via External Secrets Operator:"
info "  1. Create an ExternalSecret resource in your namespace"
info "  2. Configure it to reference: $SECRET_NAME"
info "  3. ESO will sync the secret automatically"

echo ""
info "Example ExternalSecret:"
cat << EOF
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: gcp-secrets
    kind: SecretStore
  target:
    name: my-secret
    creationPolicy: Owner
  data:
  - secretKey: value
    remoteRef:
      key: $SECRET_NAME
EOF
