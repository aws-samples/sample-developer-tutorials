#!/bin/bash
set -e

# Generate a random suffix
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Temporary directory for logs
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"

# Array to hold created resources for cleanup
CREATED_RESOURCES=()

# Function to cleanup resources
cleanup_resources() {
  echo "Cleaning up created resources..."
  for resource in "${CREATED_RESOURCES[@]}"; do
    aws wellarchitected delete-workload --workload-id "$resource" --client-request-token "del-${SUFFIX}" || true
  done
  rm -rf "${TEMP_DIR}"
}

# Trap to ensure cleanup on exit
trap cleanup_resources EXIT

# Step 1: Create Workload
echo "Step 1: Creating Workload" 
WORKLOAD_ID=$(aws wellarchitected create-workload \
  --workload-name "workload-${SUFFIX}" \
  --environment "PREPRODUCTION" \
  --lenses "wellarchitected" \
  --description "Test workload for review" \
  --review-owner "test@example.com" \
  --aws-regions "us-east-1" \
  --query 'WorkloadId' \
  --output text)
CREATED_RESOURCES+=("${WORKLOAD_ID}")
echo "Created workload: ${WORKLOAD_ID}" 

# Step 2: Get Workload
echo "Step 2: Getting Workload" 
aws wellarchitected get-workload --workload-id "${WORKLOAD_ID}" --query 'Workload.WorkloadName' --output text

# Step 3: List Workloads
echo "Step 3: Listing Workloads" 
aws wellarchitected list-workloads --query 'length(WorkloadSummaries)' --output text

# Final message
echo "PASS"