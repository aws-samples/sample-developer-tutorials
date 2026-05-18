#!/bin/bash
set -e

# Generate a unique suffix for stream names
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Create a stream with a unique name
STREAM_NAME="example-stream-${SUFFIX}"
aws kinesis create-stream --stream-name "$STREAM_NAME" --shard-count 1
echo "CreateStream status: $?"

# List all streams to verify the creation
aws kinesis list-streams --query 'StreamNames' --output text | grep "$STREAM_NAME"
echo "ListStreams status: $?"

# Wait for the stream to become active
echo "Waiting for the stream to become active..."
while true; do
    STREAM_STATUS=$(aws kinesis describe-stream --stream-name "$STREAM_NAME" --query 'StreamDescription.StreamStatus' --output text)
    if [[ $STREAM_STATUS == "ACTIVE" ]]; then
        break
    fi
    sleep 5
done

# Describe the stream to get its details
SHARD_ID=$(aws kinesis describe-stream --stream-name "$STREAM_NAME" --query 'StreamDescription.Shards[0].ShardId' --output text)
echo "DescribeStream status: $?"

# Get a shard iterator for the stream
SHARD_ITERATOR=$(aws kinesis get-shard-iterator --stream-name "$STREAM_NAME" --shard-id "$SHARD_ID" --shard-iterator-type TRIM_HORIZON --query 'ShardIterator' --output text)
echo "GetShardIterator status: $?"

# Get records from the stream
aws kinesis get-records --shard-iterator "$SHARD_ITERATOR"
echo "GetRecords status: $?"

echo "PASS"