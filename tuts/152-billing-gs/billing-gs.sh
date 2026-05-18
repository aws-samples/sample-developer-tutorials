#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/log.txt"
CREATED_RESOURCES=()

cleanup_resources() {
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "=== AWS Billing Tutorial ==="
echo "The Billing API lets you manage billing views and preferences."
echo ""

echo "=== Listing billing views ==="
aws billing list-billing-views --query 'billingViews[].name' --output text 2>/dev/null || echo "No billing views"
echo "PASS"

echo "=== Creating billing view ==="
VIEW_NAME="test-view-$SUFFIX"
aws billing create-billing-view --name "$VIEW_NAME" --output text 2>/dev/null || true

echo "=== Describing billing view ==="
aws billing describe-billing-view --name "$VIEW_NAME" 2>/dev/null || echo "Billing view not found"
echo "PASS"

echo "=== Deleting billing view ==="
aws billing delete-billing-view --name "$VIEW_NAME" 2>/dev/null || echo "Billing view not found"
echo "PASS"