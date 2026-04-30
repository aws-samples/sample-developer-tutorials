# S3 Events

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Creating SQS queue for notifications

The script handles this step automatically. See `s3-events.sh` for the exact CLI commands.

## Step 2: Creating bucket with event notification

The script handles this step automatically. See `s3-events.sh` for the exact CLI commands.

## Step 3: Uploading a file to trigger notification

The script handles this step automatically. See `s3-events.sh` for the exact CLI commands.

## Step 4: Reading notification from SQS

The script handles this step automatically. See `s3-events.sh` for the exact CLI commands.

## Cleanup

The script prompts you to clean up all created resources. If you need to clean up manually, check the script log for the resource names that were created.

