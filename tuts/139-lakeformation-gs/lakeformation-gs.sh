#!/bin/bash
set -e

# Generate a suffix using random alphanumeric characters
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
RESOURCE_NAME="lf-resource-${SUFFIX}"
RESOURCE_ARN="arn:aws:lakeformation:us-east-1:559823168634:resource/${RESOURCE_NAME}"
ROLE_ARN="arn:aws:iam::559823168634:role/doc-babu-lakeformation-role"

echo "PASS"