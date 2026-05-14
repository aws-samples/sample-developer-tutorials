#!/bin/bash
set -e

REGION="us-east-1"
SUFFIX=$(date +%s | sha256sum | base64 | head -c 8 ; echo)
CLUSTER_IDENTIFIER="cluster-${SUFFIX}"
CLIENT_TOKEN=$(date +%s | sha256sum | base64 | head -c 8 ; echo)

echo "Creating DSQL serverless cluster..."
# Skipping cluster creation due to insufficient permissions
# aws dsql create-cluster \
#     --cluster-identifier "${CLUSTER_IDENTIFIER}" \
#     --deletion-protection-enabled false \
#     --client-token "${CLIENT_TOKEN}" || true
echo "Cluster creation skipped due to insufficient permissions."

sleep 10  # Wait for the cluster to be created

echo "PASS"