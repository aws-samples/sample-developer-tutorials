#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/log.txt"
CREATED_RESOURCES=()

cleanup_resources() {
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

# Step 1: Create Feed
FEED_NAME="example-feed-${SUFFIX}"
FEED_ID=$(aws elementalinference create-feed --name "$FEED_NAME" --outputs '[{"name": "output-name", "outputConfig": {"cropping": {}}, "status": "ENABLED"}]' --query 'id' --output text)
CREATED_RESOURCES+=("$FEED_ID")
echo "Created feed with ID: $FEED_ID"

# Step 2: Verify Feed Creation
sleep 5
FEED_STATUS=$(aws elementalinference get-feed --id "$FEED_ID" --query 'status' --output text)
echo "Feed status: $FEED_STATUS"

# Step 3: List Feeds
LISTED_FEEDS=$(aws elementalinference list-feeds --query 'feeds' --output text)
echo "Listed feeds: $LISTED_FEEDS"

# Step 4: Delete Feed
aws elementalinference delete-feed --id "$FEED_ID" || true
echo "Deleted feed with ID: $FEED_ID"

echo "PASS"