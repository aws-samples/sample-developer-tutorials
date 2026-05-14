#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
  echo "Cleaning up created resources..."
  for resource in "${CREATED_RESOURCES[@]}"; do
    aws detective delete-graph --graph-arn "$resource" || true
  done
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "Step 1: Creating Detective graph..." 
GRAPH_ARN=$(aws detective create-graph --query 'GraphArn' --output text)
echo "Graph: $GRAPH_ARN" 
CREATED_RESOURCES+=("$GRAPH_ARN")

echo "Step 2: Listing graphs..." 
aws detective list-graphs --query 'GraphList[0].Arn' --output text 

echo "Step 3: Deleting graph..." 
aws detective delete-graph --graph-arn "$GRAPH_ARN" || true

echo "PASS" 