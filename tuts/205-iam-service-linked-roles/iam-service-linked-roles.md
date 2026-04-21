# Iam Service Linked Roles

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Listing service-linked roles

The script handles this step automatically. See `iam-service-linked-roles.sh` for the exact CLI commands.

## Step 2: Counting roles by type"; echo "  Service-linked: $(aws iam list-roles --query 'Roles[?starts_with(Path, `/aws-service-role/`)] | length(@)' --output text)

The script handles this step automatically. See `iam-service-linked-roles.sh` for the exact CLI commands.

