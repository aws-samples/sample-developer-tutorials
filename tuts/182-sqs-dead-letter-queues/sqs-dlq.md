# Sqs Dlq

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Creating DLQ

The script handles this step automatically. See `sqs-dlq.sh` for the exact CLI commands.

## Step 2: Creating main queue with redrive

The script handles this step automatically. See `sqs-dlq.sh` for the exact CLI commands.

## Step 3: Sending a message

The script handles this step automatically. See `sqs-dlq.sh` for the exact CLI commands.

## Step 4: Receiving without deleting (simulating failure)

The script handles this step automatically. See `sqs-dlq.sh` for the exact CLI commands.

## Step 5: Checking DLQ

The script handles this step automatically. See `sqs-dlq.sh` for the exact CLI commands.

## Cleanup

The script prompts you to clean up all created resources. If you need to clean up manually, check the script log for the resource names that were created.

