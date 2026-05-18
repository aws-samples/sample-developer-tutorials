#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
FEED_NAME="example-feed-${SUFFIX}"

# Create Feed
FEED_ID=$(aws elementalinference create-feed --name "$FEED_NAME" --outputs '[{"name": "output-name", "outputConfig": {"cropping": {}}, "status": "ENABLED"}]' --query 'id' --output text)
echo "Created feed with ID: $FEED_ID"

# Verify Feed Creation
sleep 5
FEED_STATUS=$(aws elementalinference get-feed --id "$FEED_ID" --query 'status' --output text)
echo "Feed status: $FEED_STATUS"

# List Feeds
LISTED_FEEDS=$(aws elementalinference list-feeds --query 'feeds' --output text)
echo "Listed feeds: $LISTED_FEEDS"

# Delete Feed
aws elementalinference delete-feed --id "$FEED_ID" || true
echo "Deleted feed with ID: $FEED_ID"

echo "PASS"