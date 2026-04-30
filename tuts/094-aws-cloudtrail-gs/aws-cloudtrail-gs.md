# Enable CloudTrail logging and look up recent events

This tutorial shows you how to create an AWS CloudTrail trail that logs API activity to an S3 bucket, look up recent events, and clean up.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions for `cloudtrail:CreateTrail`, `cloudtrail:StartLogging`, `cloudtrail:LookupEvents`, `cloudtrail:DescribeTrails`, `cloudtrail:DeleteTrail`, `s3:CreateBucket`, `s3:PutBucketPolicy`, `s3:DeleteBucket`

## Step 1: Create an S3 bucket for trail logs

CloudTrail delivers log files to an S3 bucket. Create a bucket with a unique name:

```bash
BUCKET_NAME="cloudtrail-tut-$(openssl rand -hex 4)-$(aws sts get-caller-identity --query Account --output text)"

aws s3api create-bucket --bucket "$BUCKET_NAME" \
    --create-bucket-configuration LocationConstraint="$AWS_DEFAULT_REGION"
```

For `us-east-1`, omit the `--create-bucket-configuration` parameter.

## Step 2: Set the bucket policy for CloudTrail

CloudTrail requires a bucket policy that grants it permission to check the bucket ACL and write log files:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

cat > bucket-policy.json << EOF
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

aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy file://bucket-policy.json
```

The first statement lets CloudTrail verify bucket ownership. The second lets it write log files under the `AWSLogs/` prefix.

## Step 3: Create a trail

Create a trail that points to your S3 bucket:

```bash
TRAIL_NAME="tutorial-trail-$(openssl rand -hex 4)"

aws cloudtrail create-trail --name "$TRAIL_NAME" --s3-bucket-name "$BUCKET_NAME" \
    --query '{Trail:Name,Bucket:S3BucketName}' --output table
```

The trail is created but not yet logging. By default it records management events in all Regions.

## Step 4: Start logging

```bash
aws cloudtrail start-logging --name "$TRAIL_NAME"
```

CloudTrail begins recording API activity and delivering log files to the S3 bucket within about 15 minutes.

## Step 5: Look up recent events

Use `lookup-events` to search the last 10 minutes of API activity:

```bash
START_TIME=$(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -u -v-10M +%Y-%m-%dT%H:%M:%SZ)

aws cloudtrail lookup-events \
    --start-time "$START_TIME" \
    --max-results 5 \
    --query 'Events[].{Time:EventTime,Name:EventName,User:Username}' --output table
```

This returns events from the Event history, which is available regardless of whether a trail exists. The trail you created delivers the same events (plus more detail) to S3.

## Step 6: Describe the trail

```bash
aws cloudtrail describe-trails --trail-name-list "$TRAIL_NAME" \
    --query 'trailList[0].{Name:Name,Bucket:S3BucketName,IsMultiRegion:IsMultiRegionTrail}' \
    --output table
```

## Cleanup

Delete the trail, then empty and delete the S3 bucket:

```bash
aws cloudtrail delete-trail --name "$TRAIL_NAME"
aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet
aws s3 rb "s3://$BUCKET_NAME"
```

The script automates all steps including cleanup. Run it with:

```bash
bash aws-cloudtrail-gs.sh
```
