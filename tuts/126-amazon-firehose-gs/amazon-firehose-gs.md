# Amazon Firehose Gs

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Creating S3 bucket: $BUCKET

The script handles this step automatically. See `amazon-firehose-gs.sh` for the exact CLI commands.

## Step 2: Creating IAM role

The script handles this step automatically. See `amazon-firehose-gs.sh` for the exact CLI commands.

## Step 3: Creating delivery stream: $STREAM_NAME

The script handles this step automatically. See `amazon-firehose-gs.sh` for the exact CLI commands.

## Step 4: Sending records

The script handles this step automatically. See `amazon-firehose-gs.sh` for the exact CLI commands.

## Step 5: Describing stream

The script handles this step automatically. See `amazon-firehose-gs.sh` for the exact CLI commands.

## Cleanup

The script prompts you to clean up all created resources. If you need to clean up manually, check the script log for the resource names that were created.

