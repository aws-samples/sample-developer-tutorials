# Ec2 Volumes

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Listing volumes

The script handles this step automatically. See `ec2-volumes.sh` for the exact CLI commands.

## Step 2: Volume summary"; echo "  Total: $(aws ec2 describe-volumes --query 'Volumes | length(@)' --output text) volumes

The script handles this step automatically. See `ec2-volumes.sh` for the exact CLI commands.

