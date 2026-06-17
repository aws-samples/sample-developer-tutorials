#!/bin/bash
set -e

# Title Banner
echo "=== AWS Firehose Tutorial: Creating and Testing a Delivery Stream ==="
echo "This tutorial will guide you through creating an AWS Firehose delivery stream, waiting for it to become active, and putting a record into it."
echo ""

# Setup logging
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
if [ -t 1 ]; then 
declare -a CREATED_RESOURCES=()

cleanup_resources() {
  for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
    RESOURCE=(${CREATED_RESOURCES[$i]})
    case ${RESOURCE[0]} in
      stream) aws firehose delete-delivery-stream --delivery-stream-name "${RESOURCE[1]}" ;;
    esac
  done
}
trap cleanup_resources EXIT

REGION="${AWS_DEFAULT_REGION:-us-east-1}"

echo "=== Step 1: Creating Delivery Stream ==="
echo "We are creating an AWS Firehose delivery stream to transport data to an S3 bucket."
echo "The delivery stream is named uniquely to avoid conflicts and is configured to use DirectPut for simplicity."
echo ""
STREAM="test-stream-${SUFFIX}"
ROLE_ARN="${TUTORIAL_ROLE_ARN:?Set TUTORIAL_ROLE_ARN or pass as argument}"
aws firehose create-delivery-stream \
  --tags Key=project,Value=doc-smith Key=tutorial,Value=firehose-gs \
  --delivery-stream-name "$STREAM" \
  --delivery-stream-type DirectPut \
  --extended-s3-destination-configuration "RoleARN=$ROLE_ARN,BucketARN=arn:aws:s3:::${TUTORIAL_BUCKET:?Set TUTORIAL_BUCKET},Prefix=firehose-${SUFFIX}/"
CREATED_RESOURCES+=("stream:$STREAM")
echo "Result: Delivery stream created with name $STREAM"
echo ""

echo "=== Step 2: Waiting for Stream to Become Active ==="
echo "After creating the delivery stream, we need to wait for it to become active before we can use it."
echo "This step ensures that the stream is ready to accept data."
echo ""
for i in $(seq 1 12); do
  STATUS=$(aws firehose describe-delivery-stream --delivery-stream-name "$STREAM" --query 'DeliveryStreamDescription.DeliveryStreamStatus' --output text)
  if [ "$STATUS" = "ACTIVE" ]; then break; fi
  sleep 5
done
echo "Result: Status of the delivery stream is $STATUS"
echo ""

echo "=== Step 3: Putting Record into the Stream ==="
echo "Now that the delivery stream is active, we can put a record into it."
echo "This demonstrates how to send data to the stream, which will then be delivered to the configured S3 bucket."
echo ""
aws firehose put-record --delivery-stream-name "$STREAM" --record '{"Data":"aGVsbG8gZmlyZWhvc2UK"}'
echo "Result: Record successfully put into the delivery stream"
echo ""

echo "Tutorial complete"
echo "In this tutorial, you learned how to create an AWS Firehose delivery stream, wait for it to become active, and put a record into it. This process demonstrates the basic functionality of AWS Firehose for data transport."
fi