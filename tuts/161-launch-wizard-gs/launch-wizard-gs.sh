#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# List existing deployments
echo "Existing Deployments:"
aws launch-wizard list-deployments --query 'deployments[].id' --output text

# Check if there are any deployments to list events for
DEPLOYMENT_IDS=$(aws launch-wizard list-deployments --query 'deployments[].id' --output text)
if [ -n "$DEPLOYMENT_IDS" ]; then
    DEPLOYMENT_ID=$(echo $DEPLOYMENT_IDS | head -n 1)
    echo "Events for Deployment $DEPLOYMENT_ID:"
    aws launch-wizard list-deployment-events --deployment-id $DEPLOYMENT_ID --query 'deploymentEvents[].id' --output text
else
    echo "No deployments available to list events for."
fi

# Example of creating a deployment (uncomment and modify as needed)
# RESPONSE=$(aws launch-wizard create-deployment \
#     --workload-name 'example-workload' \
#     --deployment-pattern-name 'example-pattern' \
#     --name "example-deployment-${SUFFIX}" \
#     --specifications '{"key1": "value1", "key2": "value2"}' \
#     --query 'id' --output text)
# echo "Created Deployment: $RESPONSE"

echo "PASS"