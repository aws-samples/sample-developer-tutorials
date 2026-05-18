#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for ARN in "${CREATED_RESOURCES[@]}"; do
        aws launch-wizard untag-resource --resource-arn "$ARN" --tag-keys project,tutorial
    done
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

# Step 1: List existing deployments
echo "Step 1: Listing existing deployments"
aws launch-wizard list-deployments --query 'deployments[].id' --output text > "$LOG_FILE"

# Step 2: Check and list events for deployments
echo "Step 2: Checking and listing events for deployments"
DEPLOYMENT_IDS=$(aws launch-wizard list-deployments --query 'deployments[].id' --output text)
if [ -n "$DEPLOYMENT_IDS" ]; then
    DEPLOYMENT_ID=$(echo "$DEPLOYMENT_IDS" | head -n 1)
    echo "Events for Deployment $DEPLOYMENT_ID:"
    aws launch-wizard list-deployment-events --deployment-id "$DEPLOYMENT_ID" --query 'deploymentEvents[].id' --output text
else
    echo "No deployments available to list events for."
fi

# Step 3: Create a deployment
echo "Step 3: Creating a deployment"
RESPONSE=$(aws launch-wizard create-deployment \
    --workload-name 'example-workload' \
    --deployment-pattern-name 'example-pattern' \
    --name "example-deployment-${SUFFIX}" \
    --specifications '{"key1": "value1", "key2": "value2"}' \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=launch-wizard-gs \
    --query 'id' --output text)
echo "Created Deployment: $RESPONSE"
CREATED_RESOURCES+=("$RESPONSE")

echo "PASS"
