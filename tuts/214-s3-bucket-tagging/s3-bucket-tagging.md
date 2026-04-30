# S3 Bucket Tagging

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Creating bucket"; aws s3api create-bucket --bucket "$B

The script handles this step automatically. See `s3-bucket-tagging.sh` for the exact CLI commands.

## Step 2: Adding tags"; aws s3api put-bucket-tagging --bucket "$B

The script handles this step automatically. See `s3-bucket-tagging.sh` for the exact CLI commands.

## Step 3: Getting tags"; aws s3api get-bucket-tagging --bucket "$B

The script handles this step automatically. See `s3-bucket-tagging.sh` for the exact CLI commands.

## Step 4: Deleting tags"; aws s3api delete-bucket-tagging --bucket "$B"; echo "  Tags deleted

The script handles this step automatically. See `s3-bucket-tagging.sh` for the exact CLI commands.

## Cleanup

The script prompts you to clean up all created resources. If you need to clean up manually, check the script log for the resource names that were created.

