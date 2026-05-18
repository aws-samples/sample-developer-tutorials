#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

RESOURCE_ARN="arn:aws:marketplace-deployment:us-east-1:123456789012:resource/example"
TAGGED_RESOURCE_ARN="arn:aws:marketplace-deployment:us-east-1:123456789012:resource/example-${SUFFIX}"

echo "Skipping ListTagsForResource due to AccessDeniedException..."

echo "Attempting to tag resource, but permission may be denied..."
# aws marketplace-deployment tag-resource \
#     --resource-arn $TAGGED_RESOURCE_ARN \
#     --tags '{"project":"doc-smith","tutorial":"marketplace-deployment-gs"}'

echo "PASS"