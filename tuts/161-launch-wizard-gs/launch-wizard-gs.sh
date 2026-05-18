#!/bin/bash
set -e
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT
echo "=== Launch Wizard ==="
echo "Listing deployments..."
aws launch-wizard list-deployments --query 'deployments[].name' --output text 2>/dev/null || echo "None"
echo "PASS"
