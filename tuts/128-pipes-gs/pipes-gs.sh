#!/bin/bash
set -e

cleanup_resources() {
  for resource in "${CREATED_RESOURCES[@]}"; do
    echo "Cleaning up: $resource"
    aws pipes delete-pipe --name "$resource" || true
  done
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
CREATED_RESOURCES=()

echo "Creating a new EventBridge Pipe."
PIPE_NAME="tutorial-pipe-$SUFFIX"
RESPONSE=$(aws pipes create-pipe \
  --name "$PIPE_NAME" \
  --role-arn "${TUTORIAL_ROLE_ARN}" \
  --source "ExampleSource" \
  --source-parameters '{"DynamicPath": "example"}' \
  --target "ExampleTarget" \
  --target-parameters '{"DynamicPath": "example"}' \
  --tags '{"Environment": "Tutorial"}' \
  --query 'PipeArn' --output text)
CREATED_RESOURCES+=("$PIPE_NAME")
echo "Created EventBridge Pipe with ARN: $RESPONSE"

echo "Verifying the creation of the EventBridge Pipe."
aws pipes describe-pipe --name "$PIPE_NAME"

echo "PASS"
