#!/bin/bash
set -euo pipefail

# tunnel.sh - IAP tunnel management for kubectl and SSH access
# Uses Identity-Aware Proxy for zero-trust access to private GKE clusters

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-gke-primary-cluster}"
CLUSTER_ZONE="${CLUSTER_ZONE:-us-central1}"
PROJECT_ID="${PROJECT_ID:-}"
BASTION_NAME="${BASTION_NAME:-gke-bastion}"
LOCAL_PORT="${LOCAL_PORT:-8888}"
REMOTE_PORT="${REMOTE_PORT:-8888}"

# Helper functions
die() {
    echo -e "${RED}Error: $*${NC}" >&2
    exit 1
}

info() {
    echo -e "${BLUE}$*${NC}"
}

success() {
    echo -e "${GREEN}$*${NC}"
}

usage() {
    cat << EOF
usage: tunnel.sh [COMMAND] [OPTIONS]

COMMANDS:
  kubectl   - Create IAP tunnel to kubectl API server
  ssh       - Create IAP tunnel for SSH access
  list      - List available bastion instances
  help      - Show this help message

OPTIONS:
  --cluster-name NAME   - Name of GKE cluster (default: $CLUSTER_NAME)
  --zone ZONE          - GCP zone (default: $CLUSTER_ZONE)
  --project-id ID      - GCP project ID (default: from gcloud config)
  --bastion NAME       - Name of bastion instance (default: $BASTION_NAME)
  --local-port PORT    - Local port to bind (default: $LOCAL_PORT)
  --remote-port PORT   - Remote port to connect to (default: $REMOTE_PORT)

EXAMPLES:
  # Connect kubectl via IAP
  ./tunnel.sh kubectl --cluster-name gke-primary --zone us-central1

  # SSH into bastion via IAP
  ./tunnel.sh ssh --bastion gke-bastion --local-port 2222

  # List available bastions
  ./tunnel.sh list
EOF
}

# Parse arguments
COMMAND="${1:-help}"
shift || true

while [[ $# -gt 0 ]]; do
    case $1 in
        --cluster-name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --zone)
            CLUSTER_ZONE="$2"
            shift 2
            ;;
        --project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        --bastion)
            BASTION_NAME="$2"
            shift 2
            ;;
        --local-port)
            LOCAL_PORT="$2"
            shift 2
            ;;
        --remote-port)
            REMOTE_PORT="$2"
            shift 2
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

# Validate GCP authentication
if [[ -z "$PROJECT_ID" ]]; then
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null) || die "PROJECT_ID not set and not configured in gcloud"
fi

info "Using PROJECT_ID: $PROJECT_ID"

case "$COMMAND" in
    kubectl)
        info "Setting up kubectl IAP tunnel..."
        info "Creating tunnel to GKE API server on localhost:$LOCAL_PORT"
        info "This tunnel is used for private GKE clusters with IAP"

        # Get cluster credentials first
        info "Getting cluster credentials..."
        gcloud container clusters get-credentials "$CLUSTER_NAME" \
            --zone "$CLUSTER_ZONE" \
            --project "$PROJECT_ID" 2>/dev/null || die "Failed to get cluster credentials"

        # The actual kubectl commands already use IAP via gcloud auth plugin
        success "Cluster credentials configured for IAP access"
        info "You can now use kubectl commands directly:"
        info "  kubectl get nodes"
        info "  kubectl get pods"
        ;;

    ssh)
        info "Setting up SSH tunnel via IAP..."
        info "Creating tunnel to $BASTION_NAME on localhost:$LOCAL_PORT"

        # Check if instance exists
        if ! gcloud compute instances describe "$BASTION_NAME" \
            --zone "$CLUSTER_ZONE" \
            --project "$PROJECT_ID" &>/dev/null; then
            die "Bastion instance not found: $BASTION_NAME"
        fi

        success "Starting IAP tunnel (Ctrl+C to stop)..."
        # Create IAP tunnel for SSH
        gcloud compute start-iap-tunnel "$BASTION_NAME" "$REMOTE_PORT" \
            --local-host-port="localhost:$LOCAL_PORT" \
            --zone="$CLUSTER_ZONE" \
            --project="$PROJECT_ID" \
            || die "Failed to create IAP tunnel"
        ;;

    list)
        info "Listing available bastion instances..."
        gcloud compute instances list \
            --filter="zone:$CLUSTER_ZONE AND labels.bastion=true" \
            --project "$PROJECT_ID" \
            --format="table(name, zone, INTERNAL_IP, EXTERNAL_IP, status)" \
            || info "No bastion instances found with label bastion=true"
        ;;

    help|--help|-h)
        usage
        ;;

    *)
        die "Unknown command: $COMMAND. Use 'tunnel.sh help' for usage."
        ;;
esac
