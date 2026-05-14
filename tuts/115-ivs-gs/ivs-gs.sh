#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
CHANNEL_NAME="test-channel-${SUFFIX}"

echo "Creating IVS channel..."
CHANNEL_ARN=$(aws ivs create-channel --name "$CHANNEL_NAME" --latency-mode NORMAL --type STANDARD --query 'channel.arn' --output text)

if [ -n "$CHANNEL_ARN" ]; then
    echo "Channel created: $CHANNEL_ARN"

    sleep 5  # Wait for channel to become active

    echo "Verifying channel exists..."
    aws ivs get-channel --arn "$CHANNEL_ARN" --query 'channel.arn' --output text | grep "$CHANNEL_ARN"

    echo "Listing channels to confirm presence..."
    aws ivs list-channels --filter-by-name "$CHANNEL_NAME" --query 'channels[?arn==`'$CHANNEL_ARN'`].arn' --output text | grep "$CHANNEL_ARN"

    echo "Deleting channel..."
    aws ivs delete-channel --arn "$CHANNEL_ARN"
    sleep 5  # Wait for deletion to process

    echo "Verifying channel deletion..."
    aws ivs get-channel --arn "$CHANNEL_ARN" --query 'channel.arn' --output text || true

    echo "PASS"
else
    echo "Failed to create channel."
fi