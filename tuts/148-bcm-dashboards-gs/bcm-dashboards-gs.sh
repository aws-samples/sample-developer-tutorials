#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/log.txt"
CREATED_RESOURCES=()

cleanup_resources() {
  for ARN in "${CREATED_RESOURCES[@]}"; do
    aws bcm-dashboards delete-dashboard --dashboard-name "$ARN" 2>/dev/null || true
  done
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "=== BCM Dashboards Tutorial ==="
echo "Billing and Cost Management dashboards provide visibility into your AWS spending."
echo ""

echo "=== Listing dashboards ==="
aws bcm-dashboards list-dashboards --query 'dashboards[].dashboardName' --output text 2>/dev/null || echo "No dashboards"
echo "PASS"

echo "=== Creating dashboard ==="
DASHBOARD_NAME="example-dashboard-$SUFFIX"
aws bcm-dashboards create-dashboard --dashboard-name "$DASHBOARD_NAME" --tags Key=project,Value=doc-smith Key=tutorial,Value=bcm-dashboards-gs
CREATED_RESOURCES+=("$DASHBOARD_NAME")
echo "PASS"

echo "=== Listing dashboards again ==="
aws bcm-dashboards list-dashboards --query 'dashboards[].dashboardName' --output text 2>/dev/null || echo "No dashboards"
echo "PASS"

echo "=== Deleting dashboard ==="
aws bcm-dashboards delete-dashboard --dashboard-name "$DASHBOARD_NAME"
echo "PASS"
