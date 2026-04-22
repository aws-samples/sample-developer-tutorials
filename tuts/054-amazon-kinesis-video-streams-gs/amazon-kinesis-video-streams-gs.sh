#!/bin/bash

# Amazon Kinesis Video Streams Getting Started Script
# This script demonstrates how to create a Kinesis video stream, get endpoints for uploading and viewing video,
# and clean up resources when done.

# Set up logging
LOG_FILE="kinesis-video-streams-tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Amazon Kinesis Video Streams tutorial script at $(date)"
echo "All commands and outputs will be logged to $LOG_FILE"

# Function to handle errors
handle_error() {
    echo "ERROR: $1"
    echo "Attempting to clean up resources..."
    cleanup_resources
    exit 1
}

# Function to check command output for errors
check_error() {
    local output="$1"
    local command_name="$2"
    
    if echo "$output" | grep -i "error" > /dev/null; then
        handle_error "Error detected in $command_name output: $output"
    fi
}

# Function to clean up resources
cleanup_resources() {
    if [ -n "$STREAM_ARN" ]; then
        echo "Deleting Kinesis video stream: $STREAM_NAME (ARN: $STREAM_ARN)"
        DELETE_STREAM_OUTPUT=$(aws kinesisvideo delete-stream --stream-arn "$STREAM_ARN")
        echo "$DELETE_STREAM_OUTPUT"
        echo "Stream deleted."
    elif [ -n "$STREAM_NAME" ]; then
        echo "Stream ARN not available. Attempting to delete by name: $STREAM_NAME"
        # Try to get the ARN first
        DESCRIBE_OUTPUT=$(aws kinesisvideo describe-stream --stream-name "$STREAM_NAME" 2>/dev/null)
        if [ $? -eq 0 ]; then
            STREAM_ARN=$(echo "$DESCRIBE_OUTPUT" | grep -o '"StreamARN": "[^"]*' | cut -d'"' -f4)
            if [ -n "$STREAM_ARN" ]; then
                echo "Found ARN: $STREAM_ARN"
                DELETE_STREAM_OUTPUT=$(aws kinesisvideo delete-stream --stream-arn "$STREAM_ARN")
                echo "$DELETE_STREAM_OUTPUT"
                echo "Stream deleted."
            else
                echo "Could not extract ARN from describe-stream output."
            fi
        else
            echo "Could not get stream details. Stream may not exist or may have already been deleted."
        fi
    fi
}

# Generate a random stream name suffix to avoid conflicts
RANDOM_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
STREAM_NAME="KVSTutorialStream-${RANDOM_SUFFIX}"

echo "=========================================="
echo "STEP 1: Create a Kinesis Video Stream"
echo "=========================================="
echo "Creating stream: $STREAM_NAME"

# Create the Kinesis video stream
CREATE_STREAM_OUTPUT=$(aws kinesisvideo create-stream --stream-name "$STREAM_NAME" --data-retention-in-hours 24 --tags Key=tutorial,Value=amazon-kinesis-video-streams-gs)
check_error "$CREATE_STREAM_OUTPUT" "create-stream"
echo "$CREATE_STREAM_OUTPUT"

# Extract the stream ARN
STREAM_ARN=$(echo "$CREATE_STREAM_OUTPUT" | grep -o '"StreamARN": "[^"]*' | cut -d'"' -f4)
if [ -z "$STREAM_ARN" ]; then
    handle_error "Failed to extract stream ARN"
fi
echo "Stream ARN: $STREAM_ARN"

# Wait for the stream to become active
echo "Waiting for stream to become active..."
sleep 5

echo "=========================================="
echo "STEP 2: Verify Stream Creation"
echo "=========================================="
DESCRIBE_STREAM_OUTPUT=$(aws kinesisvideo describe-stream --stream-name "$STREAM_NAME")
check_error "$DESCRIBE_STREAM_OUTPUT" "describe-stream"
echo "$DESCRIBE_STREAM_OUTPUT"

echo "=========================================="
echo "STEP 3: List Available Streams"
echo "=========================================="
LIST_STREAMS_OUTPUT=$(aws kinesisvideo list-streams)
check_error "$LIST_STREAMS_OUTPUT" "list-streams"
echo "$LIST_STREAMS_OUTPUT"

echo "=========================================="
echo "STEP 4: Get Data Endpoint for Uploading Video"
echo "=========================================="
GET_ENDPOINT_OUTPUT=$(aws kinesisvideo get-data-endpoint --stream-name "$STREAM_NAME" --api-name PUT_MEDIA)
check_error "$GET_ENDPOINT_OUTPUT" "get-data-endpoint"
echo "$GET_ENDPOINT_OUTPUT"

# Extract the endpoint URL
PUT_ENDPOINT=$(echo "$GET_ENDPOINT_OUTPUT" | grep -o '"DataEndpoint": "[^"]*' | cut -d'"' -f4)
if [ -z "$PUT_ENDPOINT" ]; then
    handle_error "Failed to extract PUT_MEDIA endpoint"
fi
echo "PUT_MEDIA Endpoint: $PUT_ENDPOINT"

echo "=========================================="
echo "STEP 5: Get Data Endpoint for Viewing Video"
echo "=========================================="
GET_HLS_ENDPOINT_OUTPUT=$(aws kinesisvideo get-data-endpoint --stream-name "$STREAM_NAME" --api-name GET_HLS_STREAMING_SESSION_URL)
check_error "$GET_HLS_ENDPOINT_OUTPUT" "get-data-endpoint-hls"
echo "$GET_HLS_ENDPOINT_OUTPUT"

# Extract the HLS endpoint URL
HLS_ENDPOINT=$(echo "$GET_HLS_ENDPOINT_OUTPUT" | grep -o '"DataEndpoint": "[^"]*' | cut -d'"' -f4)
if [ -z "$HLS_ENDPOINT" ]; then
    handle_error "Failed to extract GET_HLS_STREAMING_SESSION_URL endpoint"
fi
echo "GET_HLS_STREAMING_SESSION_URL Endpoint: $HLS_ENDPOINT"

echo "=========================================="
echo "STEP 6: Instructions for Sending Data to the Stream"
echo "=========================================="
echo "To send data to your Kinesis video stream, you need to:"
echo "1. Set up the Kinesis Video Streams Producer SDK with GStreamer"
echo "2. Configure your AWS credentials as environment variables:"
echo "   export AWS_ACCESS_KEY_ID=YourAccessKey"
echo "   export AWS_SECRET_ACCESS_KEY=YourSecretKey"
echo "   export AWS_DEFAULT_REGION=YourAWSRegion"
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
echo "Do you want to clean up all created resources? (y/n): "
if [ -t 0 ]; then
    read -r CLEANUP_CHOICE
else
    CLEANUP_CHOICE=y
fi

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    echo "Starting cleanup..."
    cleanup_resources
    echo "Cleanup completed."
else
    echo "Skipping cleanup. Resources will remain in your AWS account."
    echo "To manually delete the stream later, run:"
    echo "aws kinesisvideo delete-stream --stream-arn \"$STREAM_ARN\""
fi

echo "Script completed at $(date)"