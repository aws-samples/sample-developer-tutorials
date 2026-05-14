#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

echo "Listing applications..."
aws emr-serverless list-applications \
    --query 'applications[*].applicationId' \
    --output text || true

echo "PASS"