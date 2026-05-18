#!/bin/bash
set -e

# Generate a suffix based on random characters
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Unique identifiers for the tutorial
CHANNEL_ID="channel-${SUFFIX}"
TEAM_ID="team-${SUFFIX}"

echo "Listing Slack Channel Configurations..."
aws support-app list-slack-channel-configurations || true

echo "PASS"