#!/bin/bash
set -e

TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
  echo "Cleaning up created resources..."
  for resource in "${CREATED_RESOURCES[@]}"; do
    aws connectcases delete-domain --domainId "$resource" || true
  done
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
DOMAIN_NAME="test-domain-${SUFFIX}"

echo "Step 1: Creating domain..." 
DOMAIN_ID=$(aws connectcases create-domain --name "$DOMAIN_NAME" --query 'domainId' --output text)
echo "Domain created with ID: $DOMAIN_ID" 
CREATED_RESOURCES+=("$DOMAIN_ID")
DOMAIN_ARN=$(aws connectcases get-domain --domain-id "$DOMAIN_ID" --query 'domainArn' --output text)
aws connectcases tag-resource --arn "$DOMAIN_ARN" --tags '{"project":"doc-smith","tutorial":"connectcases-gs"}'

echo "PASS" 

echo "Step 2: Deleting domain..." 
aws connectcases delete-domain --domainId "$DOMAIN_ID" || true
sleep 5  # Wait for deletion to propagate
