#!/bin/bash
set -euo pipefail

# validate-env.sh - Pre-flight environment checks for GCP IaC deployment
# This script validates that all required tools and permissions are configured

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0

echo -e "${BLUE}=== GCP Infrastructure Environment Validation ===${NC}\n"

# Function to check if command exists
check_command() {
    local cmd=$1
    local version_flag=${2:---version}
    if command -v "$cmd" &> /dev/null; then
        local version=$("$cmd" $version_flag 2>&1 | head -n1)
        echo -e "${GREEN}✓${NC} $cmd: $version"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗${NC} $cmd not found. Please install $cmd."
        ((CHECKS_FAILED++))
    fi
}

# Function to check GCP authentication
check_gcp_auth() {
    echo -e "\n${BLUE}Checking GCP Authentication...${NC}"
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        local account=$(gcloud config get-value account)
        echo -e "${GREEN}✓${NC} GCP authenticated as: $account"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}✗${NC} Not authenticated with GCP. Run: gcloud auth login"
        ((CHECKS_FAILED++))
    fi
}

# Function to check gcloud project
check_gcp_project() {
    echo -e "\n${BLUE}Checking GCP Project Configuration...${NC}"
    if [[ -z "${PROJECT_ID:-}" ]]; then
        echo -e "${YELLOW}! PROJECT_ID not set in environment${NC}"
        if gcloud config get-value project &> /dev/null; then
            export PROJECT_ID=$(gcloud config get-value project)
            echo -e "${GREEN}✓${NC} Using gcloud configured project: $PROJECT_ID"
            ((CHECKS_PASSED++))
        else
            echo -e "${RED}✗${NC} No project configured. Run: gcloud config set project YOUR_PROJECT_ID"
            ((CHECKS_FAILED++))
        fi
    else
        echo -e "${GREEN}✓${NC} PROJECT_ID: $PROJECT_ID"
        ((CHECKS_PASSED++))
    fi
}

# Function to check required IAM roles
check_iam_roles() {
    echo -e "\n${BLUE}Checking IAM Roles (requires permissions to check)...${NC}"
    if [[ -n "${PROJECT_ID:-}" ]]; then
        # This is informational only, as it requires specific permissions
        echo -e "${YELLOW}!${NC} Ensure your account has these IAM roles:"
        echo "  - roles/compute.admin (for VPC, firewall, Cloud NAT)"
        echo "  - roles/container.admin (for GKE)"
        echo "  - roles/iam.securityAdmin (for IAM bindings)"
        echo "  - roles/secretmanager.admin (for Secret Manager)"
        echo "  - roles/artifactregistry.admin (for Artifact Registry)"
        echo "  - roles/cloudsql.admin (for Cloud SQL)"
    fi
}

# Function to check kubectl kubeconfig
check_kubeconfig() {
    echo -e "\n${BLUE}Checking Kubernetes Configuration...${NC}"
    if [[ -f "$HOME/.kube/config" ]]; then
        local clusters=$(kubectl config get-clusters 2>/dev/null | wc -l)
        echo -e "${GREEN}✓${NC} kubeconfig found with $((clusters - 1)) cluster(s)"
        ((CHECKS_PASSED++))
    else
        echo -e "${YELLOW}!${NC} kubeconfig not found at $HOME/.kube/config"
        echo "  Run after GKE cluster creation: gcloud container clusters get-credentials <cluster-name>"
    fi
}

# Main validation flow
echo -e "${BLUE}Checking Required Tools...${NC}"
check_command "gcloud" "version"
check_command "terraform" "-version"
check_command "kubectl" "version"
check_command "helm" "version"
check_command "task" "--version"

check_gcp_auth
check_gcp_project
check_iam_roles
check_kubeconfig

# Summary
echo -e "\n${BLUE}====================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"
echo -e "${RED}Failed: $CHECKS_FAILED${NC}"

if [[ $CHECKS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}✓ All checks passed! Ready to deploy.${NC}\n"
    exit 0
else
    echo -e "\n${RED}✗ Some checks failed. Please resolve issues above.${NC}\n"
    exit 1
fi
