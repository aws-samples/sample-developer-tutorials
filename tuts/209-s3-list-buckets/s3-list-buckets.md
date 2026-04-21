# S3 List Buckets

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Listing all buckets

The script handles this step automatically. See `s3-list-buckets.sh` for the exact CLI commands.

## Step 2: Bucket count"; echo "  Total: $(aws s3api list-buckets --query 'Buckets | length(@)' --output text) buckets

The script handles this step automatically. See `s3-list-buckets.sh` for the exact CLI commands.

## Step 3: Checking public access block"; B=$(aws s3api list-buckets --query 'Buckets[0].Name' --output text); [ -n "$B" ] && [ "$B" != "None" ] && aws s3api get-public-access-block --bucket "$B" --query 'PublicAccessBlockConfiguration' --output table 2>/dev/null || echo "  No public access block

The script handles this step automatically. See `s3-list-buckets.sh` for the exact CLI commands.

