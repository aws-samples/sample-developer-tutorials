#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/ivs-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
CHANNEL_NAME="tut-channel-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$CHANNEL_ARN" ] && aws ivs delete-channel --arn "$CHANNEL_ARN" 2>/dev/null && echo "  Deleted channel"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating channel: $CHANNEL_NAME"
RESULT=$(aws ivs create-channel --name "$CHANNEL_NAME" --type STANDARD)
CHANNEL_ARN=$(echo "$RESULT" | python3 -c "import sys,json;print(json.load(sys.stdin)['channel']['arn'])")
STREAM_KEY=$(echo "$RESULT" | python3 -c "import sys,json;print(json.load(sys.stdin)['streamKey']['value'])")
echo "  Channel ARN: $CHANNEL_ARN"
echo "  Stream key: ${STREAM_KEY:0:10}..."
echo "Step 2: Getting channel details"
aws ivs get-channel --arn "$CHANNEL_ARN" --query 'channel.{Name:name,Type:type,Latency:latencyMode,Endpoint:ingestEndpoint}' --output table
echo "Step 3: Listing channels"
aws ivs list-channels --query 'channels[?starts_with(name, `tut-`)].{Name:name,ARN:arn}' --output table
echo "Step 4: Getting stream key"
aws ivs list-stream-keys --channel-arn "$CHANNEL_ARN" --query 'streamKeys[0].arn' --output text > /dev/null
echo "  Stream key retrieved (use with OBS or ffmpeg to stream)"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
