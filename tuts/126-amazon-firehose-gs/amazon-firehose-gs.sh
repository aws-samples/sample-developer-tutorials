#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/firehose-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}
[ -z "$REGION" ] && echo "ERROR: No region" && exit 1
export AWS_DEFAULT_REGION="$REGION"
ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
STREAM_NAME="tut-firehose-${RANDOM_ID}"
BUCKET="firehose-tut-${RANDOM_ID}-${ACCOUNT}"
ROLE_NAME="firehose-tut-role-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws firehose delete-delivery-stream --delivery-stream-name "$STREAM_NAME" 2>/dev/null && echo "  Deleted stream"; sleep 5; aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null; aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role"; if aws s3 ls "s3://$BUCKET" > /dev/null 2>&1; then aws s3 rm "s3://$BUCKET" --recursive --quiet; aws s3 rb "s3://$BUCKET" && echo "  Deleted bucket"; fi; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating S3 bucket: $BUCKET"
if [ "$REGION" = "us-east-1" ]; then aws s3api create-bucket --bucket "$BUCKET" > /dev/null; else aws s3api create-bucket --bucket "$BUCKET" --create-bucket-configuration LocationConstraint="$REGION" > /dev/null; fi
echo "Step 2: Creating IAM role"
ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"firehose.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
echo "  Role: $ROLE_ARN"
sleep 10
echo "Step 3: Creating delivery stream: $STREAM_NAME"
aws firehose create-delivery-stream --delivery-stream-name "$STREAM_NAME" --s3-destination-configuration "{\"RoleARN\":\"$ROLE_ARN\",\"BucketARN\":\"arn:aws:s3:::$BUCKET\",\"BufferingHints\":{\"SizeInMBs\":1,\"IntervalInSeconds\":60}}" --query 'DeliveryStreamARN' --output text
echo "  Waiting for stream..."
for i in $(seq 1 20); do STATUS=$(aws firehose describe-delivery-stream --delivery-stream-name "$STREAM_NAME" --query 'DeliveryStreamDescription.DeliveryStreamStatus' --output text); echo "  $STATUS"; [ "$STATUS" = "ACTIVE" ] && break; sleep 5; done
echo "Step 4: Sending records"
aws firehose put-record --delivery-stream-name "$STREAM_NAME" --record '{"Data":"SGVsbG8gZnJvbSBGaXJlaG9zZQo="}' --query 'RecordId' --output text > /dev/null
aws firehose put-record-batch --delivery-stream-name "$STREAM_NAME" --records '[{"Data":"UmVjb3JkIDEK"},{"Data":"UmVjb3JkIDIK"}]' > /dev/null
echo "  Sent 3 records (1 individual + 2 batch)"
echo "Step 5: Describing stream"
aws firehose describe-delivery-stream --delivery-stream-name "$STREAM_NAME" --query 'DeliveryStreamDescription.{Name:DeliveryStreamName,Status:DeliveryStreamStatus,Destination:Destinations[0].S3DestinationDescription.BucketARN}' --output table
echo ""
echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "
read -r CHOICE
[[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup || echo "Manual: aws firehose delete-delivery-stream --delivery-stream-name $STREAM_NAME"
