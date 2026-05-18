#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()
trap cleanup_resources EXIT

cleanup_resources() {
  # Add cleanup logic if needed
}

echo "Listing streams:" &>> "$LOG_FILE"
STREAMS=$(aws dynamodbstreams list-streams --output text --query 'Streams[*].StreamArn' &>> "$LOG_FILE")

if [ -n "$STREAMS" ]; then
  STREAM_ARN=$(echo "$STREAMS" | head -n 1)
  echo "Describing stream: $STREAM_ARN" &>> "$LOG_FILE"
  STREAM_DESCRIPTION=$(aws dynamodbstreams describe-stream --stream-arn "$STREAM_ARN" --output text &>> "$LOG_FILE")
  SHARD_ID=$(echo "$STREAM_DESCRIPTION" | grep -oP '(?<=ShardId: ).*' | head -n 1)
  SHARD_ITERATOR_TYPE='TRIM_HORIZON'
  echo "Getting shard iterator for shard: $SHARD_ID" &>> "$LOG_FILE"
  SHARD_ITERATOR=$(aws dynamodbstreams get-shard-iterator --stream-arn "$STREAM_ARN" --shard-id "$SHARD_ID" --shard-iterator-type "$SHARD_ITERATOR_TYPE" --query 'ShardIterator' --output text &>> "$LOG_FILE")
  echo "Getting records from shard iterator:" &>> "$LOG_FILE"
  aws dynamodbstreams get-records --shard-iterator "$SHARD_ITERATOR" --limit 2 &>> "$LOG_FILE"
fi

echo "PASS"