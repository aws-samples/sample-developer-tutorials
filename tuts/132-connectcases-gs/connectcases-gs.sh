#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
DOMAIN_NAME="test-domain-${SUFFIX}"

echo "Creating domain..."
DOMAIN_ID=$(aws connectcases create-domain --name "$DOMAIN_NAME" --query 'domainId' --output text)
echo "Domain created with ID: $DOMAIN_ID"

echo "PASS"

echo "Deleting domain..."
aws connectcases delete-domain --domainId "$DOMAIN_ID" || true
sleep 5  # Wait for deletion to propagate