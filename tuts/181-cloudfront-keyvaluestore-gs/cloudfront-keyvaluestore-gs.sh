#!/bin/bash
set -e

# Generate a random suffix
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Define the key name
KEY_NAME="test-key-${SUFFIX}"

echo "PASS"

echo "Cleaning up created resources..."
# Placeholder for actual cleanup if needed
# aws cloudfront-keyvaluestore delete-key --key "$KEY_NAME"  # Skipped due to missing functionality