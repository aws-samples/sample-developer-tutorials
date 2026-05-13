#!/bin/bash
set -e
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
STREAM="test-stream-${SUFFIX}"
ROLE_ARN="arn:aws:iam::559823168634:role/doc-babu-firehose-role"

echo "Creating delivery stream: $STREAM"
aws firehose create-delivery-stream   --delivery-stream-name "$STREAM"   --delivery-stream-type DirectPut   --extended-s3-destination-configuration "RoleARN=$ROLE_ARN,BucketARN=arn:aws:s3:::doc-babu-test-bucket,Prefix=firehose-${SUFFIX}/"

echo "Waiting for stream to become active..."
for i in $(seq 1 12); do
  STATUS=$(aws firehose describe-delivery-stream --delivery-stream-name "$STREAM" --query 'DeliveryStreamDescription.DeliveryStreamStatus' --output text)
  if [ "$STATUS" = "ACTIVE" ]; then break; fi
  sleep 5
done
echo "Status: $STATUS"

echo "Putting record..."
aws firehose put-record --delivery-stream-name "$STREAM" --record '{"Data":"aGVsbG8gZmlyZWhvc2UK"}'

echo "Deleting stream..."
aws firehose delete-delivery-stream --delivery-stream-name "$STREAM"
echo "PASS"
