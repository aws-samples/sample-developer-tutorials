#!/bin/bash

# Amazon Kinesis Video Streams Getting Started Script
# This script demonstrates how to create a Kinesis video stream, get endpoints for uploading and viewing video,
# and clean up resources when done.

set -euo pipefail

# Set up logging
LOG_FILE="kinesis-video-streams-tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Amazon Kinesis Video Streams tutorial script at $(date)"
echo "All commands and outputs will be logged to $LOG_FILE"

# Function to handle errors
handle_error() {
    echo "ERROR: $1" >&2
    echo "Attempting to clean up resources..."
    cleanup_resources
    exit 1
}

# Function to check command output for errors
check_error() {
    local output="$1"
    local command_name="$2"
    
    if echo "$output" | grep -qi "error\|failed"; then
        handle_error "Error detected in $command_name output: $output"
    fi
}

# Function to safely extract JSON values using jq
extract_json_value() {
    local json_input="$1"
    local json_path="$2"
    
    if command -v jq &> /dev/null; then
        echo "$json_input" | jq -r "$json_path" 2>/dev/null || echo ""
    else
        echo "WARNING: jq not found. Using fallback parsing." >&2
        echo "$json_input" | grep -o "\"$(basename "$json_path")\": \"[^\"]*" | cut -d'"' -f4 || echo ""
    fi
}

# Function to clean up resources
cleanup_resources() {
    if [ -n "${STREAM_ARN:-}" ]; then
        echo "Deleting Kinesis video stream: ${STREAM_NAME:-unknown} (ARN: $STREAM_ARN)"
        if aws kinesisvideo delete-stream --stream-arn "$STREAM_ARN" 2>/dev/null; then
            echo "Stream deletion initiated."
        else
            echo "WARNING: Could not delete stream with ARN: $STREAM_ARN" >&2
        fi
    elif [ -n "${STREAM_NAME:-}" ]; then
        echo "Stream ARN not available. Attempting to delete by name: $STREAM_NAME"
        DESCRIBE_OUTPUT=$(aws kinesisvideo describe-stream --stream-name "$STREAM_NAME" 2>/dev/null || echo "")
        if [ -n "$DESCRIBE_OUTPUT" ]; then
            STREAM_ARN=$(extract_json_value "$DESCRIBE_OUTPUT" ".StreamInfo.StreamARN")
            if [ -n "$STREAM_ARN" ]; then
                echo "Found ARN: $STREAM_ARN"
                if aws kinesisvideo delete-stream --stream-arn "$STREAM_ARN" 2>/dev/null; then
                    echo "Stream deletion initiated."
                else
                    echo "WARNING: Could not delete stream with ARN: $STREAM_ARN" >&2
                fi
            else
                echo "Could not extract ARN from describe-stream output."
            fi
        else
            echo "Could not get stream details. Stream may not exist or may have already been deleted."
        fi
    fi
}

# Validate AWS CLI is available
if ! command -v aws &> /dev/null; then
    handle_error "AWS CLI is not installed or not found in PATH"
fi

# Validate AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    handle_error "AWS credentials are not properly configured. Please run 'aws configure'"
fi

# Generate a random stream name suffix to avoid conflicts
RANDOM_SUFFIX=$(head -c 8 /dev/urandom | xxd -p)
STREAM_NAME="KVSTutorialStream-${RANDOM_SUFFIX}"
STREAM_ARN=""
PUT_ENDPOINT=""
HLS_ENDPOINT=""

echo "=========================================="
echo "STEP 1: Create a Kinesis Video Stream"
echo "=========================================="
echo "Creating stream: $STREAM_NAME"

# Create the Kinesis video stream
if ! CREATE_STREAM_OUTPUT=$(aws kinesisvideo create-stream --stream-name "$STREAM_NAME" --data-retention-in-hours 24 --output json 2>&1); then
    handle_error "Failed to create stream: $CREATE_STREAM_OUTPUT"
fi
check_error "$CREATE_STREAM_OUTPUT" "create-stream"
echo "$CREATE_STREAM_OUTPUT"

# Extract the stream ARN safely
STREAM_ARN=$(extract_json_value "$CREATE_STREAM_OUTPUT" ".StreamARN")
if [ -z "$STREAM_ARN" ]; then
    handle_error "Failed to extract stream ARN from response"
fi
echo "Stream ARN: $STREAM_ARN"

# Wait for the stream to become active
echo "Waiting for stream to become active..."
sleep 5

echo "=========================================="
echo "STEP 2: Verify Stream Creation"
echo "=========================================="
if ! DESCRIBE_STREAM_OUTPUT=$(aws kinesisvideo describe-stream --stream-name "$STREAM_NAME" --output json 2>&1); then
    handle_error "Failed to describe stream: $DESCRIBE_STREAM_OUTPUT"
fi
check_error "$DESCRIBE_STREAM_OUTPUT" "describe-stream"
echo "$DESCRIBE_STREAM_OUTPUT"

echo "=========================================="
echo "STEP 3: List Available Streams"
echo "=========================================="
if ! LIST_STREAMS_OUTPUT=$(aws kinesisvideo list-streams --output json 2>&1); then
    handle_error "Failed to list streams: $LIST_STREAMS_OUTPUT"
fi
check_error "$LIST_STREAMS_OUTPUT" "list-streams"
echo "$LIST_STREAMS_OUTPUT"

echo "=========================================="
echo "STEP 4: Get Data Endpoint for Uploading Video"
echo "=========================================="
if ! GET_ENDPOINT_OUTPUT=$(aws kinesisvideo get-data-endpoint --stream-name "$STREAM_NAME" --api-name PUT_MEDIA --output json 2>&1); then
    handle_error "Failed to get PUT_MEDIA endpoint: $GET_ENDPOINT_OUTPUT"
fi
check_error "$GET_ENDPOINT_OUTPUT" "get-data-endpoint"
echo "$GET_ENDPOINT_OUTPUT"

# Extract the endpoint URL safely
PUT_ENDPOINT=$(extract_json_value "$GET_ENDPOINT_OUTPUT" ".DataEndpoint")
if [ -z "$PUT_ENDPOINT" ]; then
    handle_error "Failed to extract PUT_MEDIA endpoint"
fi
echo "PUT_MEDIA Endpoint: $PUT_ENDPOINT"

echo "=========================================="
echo "STEP 5: Get Data Endpoint for Viewing Video"
echo "=========================================="
if ! GET_HLS_ENDPOINT_OUTPUT=$(aws kinesisvideo get-data-endpoint --stream-name "$STREAM_NAME" --api-name GET_HLS_STREAMING_SESSION_URL --output json 2>&1); then
    handle_error "Failed to get HLS endpoint: $GET_HLS_ENDPOINT_OUTPUT"
fi
check_error "$GET_HLS_ENDPOINT_OUTPUT" "get-data-endpoint-hls"
echo "$GET_HLS_ENDPOINT_OUTPUT"

# Extract the HLS endpoint URL safely
HLS_ENDPOINT=$(extract_json_value "$GET_HLS_ENDPOINT_OUTPUT" ".DataEndpoint")
if [ -z "$HLS_ENDPOINT" ]; then
    handle_error "Failed to extract GET_HLS_STREAMING_SESSION_URL endpoint"
fi
echo "GET_HLS_STREAMING_SESSION_URL Endpoint: $HLS_ENDPOINT"

echo "=========================================="
echo "STEP 6: Instructions for Sending Data to the Stream"
echo "=========================================="
echo "To send data to your Kinesis video stream, you need to:"
echo "1. Set up the Kinesis Video Streams Producer SDK with GStreamer"
echo "2. Configure your AWS credentials using IAM roles (preferred) or environment variables"
echo "3. Upload a sample MP4 file or generate a test video stream"
echo ""
echo "For detailed instructions, refer to the tutorial documentation."

echo "=========================================="
echo "STEP 7: Instructions for Viewing the Stream"
echo "=========================================="
echo "To view your stream:"
echo "1. Open the AWS Management Console"
echo "2. Navigate to Kinesis Video Streams"
echo "3. Select your stream: $STREAM_NAME"
echo "4. Expand the Media playback section"
echo ""
echo "Alternatively, you can use the HLS endpoint to view the stream programmatically."

echo "=========================================="
echo "RESOURCES CREATED"
echo "=========================================="
echo "Kinesis Video Stream: $STREAM_NAME (ARN: $STREAM_ARN)"
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Starting cleanup..."
cleanup_resources
echo "Cleanup completed."

echo "Script completed at $(date)"