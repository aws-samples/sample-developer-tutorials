#!/bin/bash
# Empty and delete the shared tutorial S3 bucket, then delete the CloudFormation stack.
# Usage: ./cfn/cleanup-bucket.sh
set -eo pipefail

STACK_NAME="tutorial-prereqs-bucket"

BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text 2>/dev/null)

if [ -z "$BUCKET_NAME" ] || [ "$BUCKET_NAME" = "None" ]; then
    echo "No bucket stack found."
    exit 0
fi

echo "Bucket: $BUCKET_NAME"
echo ""
echo "Contents:"
aws s3 ls "s3://$BUCKET_NAME/" 2>/dev/null || echo "  (empty)"
echo ""
echo "This will permanently delete all objects and the bucket itself."
read -rp "Type the bucket name to confirm: " CONFIRM

if [ "$CONFIRM" != "$BUCKET_NAME" ]; then
    echo "Bucket name does not match. Aborting."
    exit 1
fi

echo ""
echo "Emptying bucket..."
aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet

aws s3api list-object-versions --bucket "$BUCKET_NAME" \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}, Quiet: true}' \
    --output json 2>/dev/null | \
    aws s3api delete-objects --bucket "$BUCKET_NAME" --delete file:///dev/stdin > /dev/null 2>&1 || true

aws s3api list-object-versions --bucket "$BUCKET_NAME" \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}, Quiet: true}' \
    --output json 2>/dev/null | \
    aws s3api delete-objects --bucket "$BUCKET_NAME" --delete file:///dev/stdin > /dev/null 2>&1 || true

echo "Deleting bucket: $BUCKET_NAME"
aws s3api delete-bucket --bucket "$BUCKET_NAME"

echo "Deleting stack: $STACK_NAME"
aws cloudformation delete-stack --stack-name "$STACK_NAME"
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"

echo "Done."
