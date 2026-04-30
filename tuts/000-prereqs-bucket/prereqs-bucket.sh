#!/bin/bash
# Create the shared tutorial S3 bucket and register it with CloudFormation.
# Usage: ./cfn/setup-bucket.sh
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STACK_NAME="tutorial-prereqs-bucket"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")
BUCKET_NAME="tutorial-bucket-${ACCOUNT_ID}-${REGION}"

# Check if stack already exists
STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "NONE")

if [ "$STATUS" = "CREATE_COMPLETE" ] || [ "$STATUS" = "UPDATE_COMPLETE" ]; then
    EXISTING=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
        --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text)
    echo "Bucket already exists: $EXISTING"
    exit 0
fi

echo "Creating bucket: $BUCKET_NAME"
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket already exists: $BUCKET_NAME"
else
    if [ "$REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$BUCKET_NAME"
    else
        aws s3api create-bucket --bucket "$BUCKET_NAME" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi

    aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration \
        '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

    aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        'BlockPublicAcls=true,BlockPublicPolicy=true,IgnorePublicAcls=true,RestrictPublicBuckets=true'
fi

echo "Registering bucket with CloudFormation stack: $STACK_NAME"
aws cloudformation deploy \
    --template-file "$SCRIPT_DIR/cfn-prereqs-bucket.yaml" \
    --stack-name "$STACK_NAME" \
    --parameter-overrides "BucketName=$BUCKET_NAME"

echo "Done. Bucket: $BUCKET_NAME"
echo "Other stacks can import: !ImportValue ${STACK_NAME}-BucketName"
