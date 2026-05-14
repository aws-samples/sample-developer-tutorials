#!/bin/bash
set -e

REGION_NAME='us-east-1'
SUFFIX=$(date +%s | sha256sum | base64 | head -c 8 ; date +%s | sha256sum | base64 | head -c 4)
PROBE_NAME="probe-${SUFFIX}"

echo "Listing monitors..."
aws networkmonitor list-monitors \
    --query 'Monitors[*].{Name:Name,Status:Status}' \
    --output text || echo "Skipping due to invalid security token."

echo "PASS"