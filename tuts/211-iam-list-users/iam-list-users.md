# Iam List Users

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Listing IAM users

The script handles this step automatically. See `iam-list-users.sh` for the exact CLI commands.

## Step 2: User count"; echo "  Total: $(aws iam list-users --query 'Users | length(@)' --output text) users

The script handles this step automatically. See `iam-list-users.sh` for the exact CLI commands.

