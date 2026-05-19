#!/bin/bash
set -e

cleanup_resources() {
  for resource in "${CREATED_RESOURCES[@]}"; do
    case "$resource" in
      channel-*)
        aws mediapackagev2 delete-channel --channel-id "${resource#channel-}" || true
        ;;
      channel-group-*)
        aws mediapackagev2 delete-channel-group --channel-group-name "${resource#channel-group-}" || true
        ;;
      origin-endpoint-*)
        aws mediapackagev2 delete-origin-endpoint --channel-group-name "${resource#origin-endpoint-}" || true
        ;;
      *)
        echo "Unknown resource type: $resource"
        ;;
    esac
  done
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
CREATED_RESOURCES=()

ROLE_ARN=${TUTORIAL_ROLE_ARN}

echo "Creating a channel group"
CHANNEL_GROUP_NAME="tutorial-channel-group-$SUFFIX"
CHANNEL_GROUP_ID=$(aws mediapackagev2 create-channel-group --channel-group-name "$CHANNEL_GROUP_NAME" --tags '{"Environment":"Tutorial"}' --query 'channelGroupName' --output text)
CREATED_RESOURCES+=("channel-group-$CHANNEL_GROUP_ID")
echo "Created channel group: $CHANNEL_GROUP_ID"

echo "Creating a channel"
CHANNEL_NAME="tutorial-channel-$SUFFIX"
CHANNEL_ID=$(aws mediapackagev2 create-channel --channel-group-name "$CHANNEL_GROUP_NAME" --channel-name "$CHANNEL_NAME" --tags '{"Environment":"Tutorial"}' --query 'channelName' --output text)
CREATED_RESOURCES+=("channel-$CHANNEL_ID")
echo "Created channel: $CHANNEL_ID"

echo "Creating an origin endpoint"
ORIGIN_ENDPOINT_NAME="tutorial-origin-endpoint-$SUFFIX"
ORIGIN_ENDPOINT_ID=$(aws mediapackagev2 create-origin-endpoint --channel-group-name "$CHANNEL_GROUP_NAME" --origin-endpoint-name "$ORIGIN_ENDPOINT_NAME" --container-type "HLS" --tags '{"Environment":"Tutorial"}' --query 'originEndpointName' --output text)
CREATED_RESOURCES+=("origin-endpoint-$ORIGIN_ENDPOINT_ID")
echo "Created origin endpoint: $ORIGIN_ENDPOINT_ID"

echo "PASS"
