# Lambda Dead Letter

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Creating function that always fails

The script handles this step automatically. See `lambda-dead-letter.sh` for the exact CLI commands.

## Step 2: Invoking async (will fail and go to DLQ)

The script handles this step automatically. See `lambda-dead-letter.sh` for the exact CLI commands.

## Step 3: Checking DLQ (after retries, ~3 min)

The script handles this step automatically. See `lambda-dead-letter.sh` for the exact CLI commands.

## Cleanup

The script prompts you to clean up all created resources. If you need to clean up manually, check the script log for the resource names that were created.

