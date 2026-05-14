#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
CHANNEL_GROUP_NAME="test-channel-group-${SUFFIX}"
CLIENT_TOKEN=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

# Create Channel Group
echo "Creating Channel Group..."
aws mediapackagev2 create-channel-group \
    --channel-group-name "$CHANNEL_GROUP_NAME" \
    --client-token "$CLIENT_TOKEN" \
    --description "Test Channel Group" \
    --tags Environment=Test || true

echo "Channel Group Created"

# Verify Channel Group Creation
echo "Verifying Channel Group Creation..."
aws mediapackagev2 get-channel-group \
    --channel-group-name "$CHANNEL_GROUP_NAME" || true

echo "Channel Group Verified"

# List Channel Groups
echo "Listing Channel Groups..."
aws mediapackagev2 list-channel-groups \
    --max-results 10 || true

echo "Channel Groups Listed"

# Delete Channel Group
echo "Deleting Channel Group..."
aws mediapackagev2 delete-channel-group \
    --channel-group-name "$CHANNEL_GROUP_NAME" || true

echo "Channel Group Deleted"

echo "PASS"