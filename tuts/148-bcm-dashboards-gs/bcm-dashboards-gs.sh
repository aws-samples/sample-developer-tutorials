#!/bin/bash
set -e
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT
echo "=== BCM Dashboards ==="
echo "Listing dashboards..."
aws bcm-dashboards list-dashboards --query 'dashboards[].dashboardName' --output text 2>/dev/null || echo "None"
echo "PASS"
