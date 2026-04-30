#!/bin/bash
# Tutorial: Enable CloudTrail logging and look up recent events
# Source: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-tutorial.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/cloudtrail-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Region: $REGION"
echo "Account: $ACCOUNT_ID"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
TRAIL_NAME="tutorial-trail-${RANDOM_ID}"
BUCKET_NAME="cloudtrail-tut-${RANDOM_ID}-${ACCOUNT_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws cloudtrail delete-trail --name "$TRAIL_NAME" 2>/dev/null && echo "  Deleted trail $TRAIL_NAME"
    # Empty and delete the bucket
    if aws s3 ls "s3://$BUCKET_NAME" > /dev/null 2>&1; then
        aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet 2>/dev/null
        aws s3 rb "s3://$BUCKET_NAME" 2>/dev/null && echo "  Deleted bucket $BUCKET_NAME"
    fi
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create S3 bucket for trail logs
echo "Step 1: Creating S3 bucket for trail logs: $BUCKET_NAME"
if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" > /dev/null
else
    aws s3api create-bucket --bucket "$BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint="$REGION" > /dev/null
fi

# Step 2: Set bucket policy to allow CloudTrail writes
echo "Step 2: Setting bucket policy for CloudTrail"
cat > "$WORK_DIR/bucket-policy.json" << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {"Service": "cloudtrail.amazonaws.com"},
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::$BUCKET_NAME"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {"Service": "cloudtrail.amazonaws.com"},
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/AWSLogs/$ACCOUNT_ID/*",
            "Condition": {"StringEquals": {"s3:x-amz-acl": "bucket-owner-full-control"}}
        }
    ]
}
EOF
aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy "file://$WORK_DIR/bucket-policy.json"
echo "  Bucket policy applied"

# Step 3: Create a trail
echo "Step 3: Creating trail: $TRAIL_NAME"
aws cloudtrail create-trail --name "$TRAIL_NAME" --s3-bucket-name "$BUCKET_NAME" \
    --query '{Trail:Name,Bucket:S3BucketName}' --output table

# Step 4: Start logging
echo "Step 4: Starting logging"
aws cloudtrail start-logging --name "$TRAIL_NAME"
echo "  Logging started"

# Step 5: Look up recent events
echo "Step 5: Looking up recent API events (last 10 minutes)"
START_TIME=$(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-10M +%Y-%m-%dT%H:%M:%SZ)
aws cloudtrail lookup-events \
    --start-time "$START_TIME" \
    --max-results 5 \
    --query 'Events[].{Time:EventTime,Name:EventName,User:Username}' --output table

# Step 6: Describe the trail
echo "Step 6: Describing the trail"
aws cloudtrail describe-trails --trail-name-list "$TRAIL_NAME" \
    --query 'trailList[0].{Name:Name,Bucket:S3BucketName,IsMultiRegion:IsMultiRegionTrail,IsLogging:HasCustomEventSelectors}' --output table

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Resources left running. The trail logs API activity to S3."
    echo "Manual cleanup:"
    echo "  aws cloudtrail delete-trail --name $TRAIL_NAME"
    echo "  aws s3 rm s3://$BUCKET_NAME --recursive"
    echo "  aws s3 rb s3://$BUCKET_NAME"
fi
