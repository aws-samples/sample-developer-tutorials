#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
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
if [ -z "$REGION" ]; then
  echo "Region not configured. Please run 'aws configure' and set the region."
  exit 1
fi

echo "=== Creating delivery stream ==="
STREAM="test-stream-${SUFFIX}"
ROLE_ARN="arn:aws:iam::559823168634:role/doc-babu-firehose-role"
aws firehose create-delivery-stream \
  --delivery-stream-name "$STREAM" \
  --delivery-stream-type DirectPut \
  --extended-s3-destination-configuration "RoleARN=$ROLE_ARN,BucketARN=arn:aws:s3:::doc-babu-test-bucket,Prefix=firehose-${SUFFIX}/" > "$LOG_FILE"
CREATED_RESOURCES+=("stream:$STREAM")

echo "=== Waiting for stream to become active... ==="
for i in $(seq 1 12); do
  STATUS=$(aws firehose describe-delivery-stream --delivery-stream-name "$STREAM" --query 'DeliveryStreamDescription.DeliveryStreamStatus' --output text)
  if [ "$STATUS" = "ACTIVE" ]; then break; fi
  sleep 5
done
echo "Status: $STATUS"

echo "=== Putting record... ==="
aws firehose put-record --delivery-stream-name "$STREAM" --record '{"Data":"aGVsbG8gZmlyZWhvc2UK"}'

echo "PASS"