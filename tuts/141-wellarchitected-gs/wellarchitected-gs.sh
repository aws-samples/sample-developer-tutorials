#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
CREATED_RESOURCES=()

echo "Creating workload"
WORKLOAD_NAME="workload-$SUFFIX"
LENSES="wellarchitected"
ENVIRONMENT="production"
REVIEW_OWNER="review-owner-$SUFFIX"
TAGS='{"project":"wellarchitected-tutorial"}'

OUTPUT=$(aws wellarchitected create-workload \
  --workload-name "$WORKLOAD_NAME" \
  --lenses "$LENSES" \
  --environment "$ENVIRONMENT" \
  --review-owner "$REVIEW_OWNER" \
  --tags "$TAGS" \
  --output text)

WORKLOAD_ID=$(echo "$OUTPUT" | awk '{print $2}')
CREATED_RESOURCES+=("$WORKLOAD_ID")

echo "PASS"
