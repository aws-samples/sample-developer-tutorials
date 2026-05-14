#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for ARN in "${CREATED_RESOURCES[@]}"; do
        echo "Deleting channel: $ARN" >> "$LOG_FILE"
        aws ivs delete-channel --arn "$ARN" || true
    done
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

CHANNEL_NAME="test-channel-${SUFFIX}"
echo "Creating IVS channel..." >> "$LOG_FILE"
CHANNEL_ARN=$(aws ivs create-channel --name "$CHANNEL_NAME" --latency-mode NORMAL --type STANDARD --query 'channel.arn' --output text)

if [ -n "$CHANNEL_ARN" ]; then
    echo "Channel created: $CHANNEL_ARN" >> "$LOG_FILE"
    CREATED_RESOURCES+=("$CHANNEL_ARN")

    sleep 5  # Wait for channel to become active

    echo "Verifying channel exists..." >> "$LOG_FILE"
    aws ivs get-channel --arn "$CHANNEL_ARN" --query 'channel.arn' --output text | grep "$CHANNEL_ARN" >> "$LOG_FILE"

    echo "Listing channels to confirm presence..." >> "$LOG_FILE"
    aws ivs list-channels --filter-by-name "$CHANNEL_NAME" --query 'channels[?arn==`'$CHANNEL_ARN'`].arn' --output text | grep "$CHANNEL_ARN" >> "$LOG_FILE"

    echo "Deleting channel..." >> "$LOG_FILE"
    aws ivs delete-channel --arn "$CHANNEL_ARN" || true
    sleep 5  # Wait for deletion to process

    echo "Verifying channel deletion..." >> "$LOG_FILE"
    aws ivs get-channel --arn "$CHANNEL_ARN" --query 'channel.arn' --output text || true >> "$LOG_FILE"

    echo "PASS" >> "$LOG_FILE"
else
    echo "Failed to create channel." >> "$LOG_FILE"
fi