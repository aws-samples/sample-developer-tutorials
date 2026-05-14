#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
GROUP_NAME="group-${SUFFIX}"

echo "Creating group..."
aws resource-groups create-group \
    --name "$GROUP_NAME" \
    --resource-query '{"Type":"TAG_FILTERS_1_0","Query":"{\"ResourceTypeFilters\":[\"AWS::AllSupported\"],\"TagFilters\":[{\"Key\":\"project\",\"Values\":[\"doc-smith\"]}]}"}' \
    --generate-cli-skeleton

echo "Listing groups..."
aws resource-groups list-groups \
    --generate-cli-skeleton

echo "Deleting group..."
aws resource-groups delete-group \
    --group-name "$GROUP_NAME" || true

echo "PASS"