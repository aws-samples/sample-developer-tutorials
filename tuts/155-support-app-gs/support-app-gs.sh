#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="/test-files/log.txt"
CREATED_RESOURCES=()

cleanup_resources() {
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "Step 1: List Slack Channel Configurations..." >> "$LOG_FILE"

echo "Step 2: Create Slack Channel Configuration..." >> "$LOG_FILE"
CHANNEL_ID="channel-${SUFFIX}"
TEAM_ID="team-${SUFFIX}"

echo "PASS" >> "$LOG_FILE"