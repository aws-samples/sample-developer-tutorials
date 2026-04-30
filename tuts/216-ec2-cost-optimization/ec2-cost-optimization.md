# Ec2 Cost Optimization

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Finding stopped instances (still incurring EBS charges)

The script handles this step automatically. See `ec2-cost-optimization.sh` for the exact CLI commands.

## Step 2: Finding unattached EBS volumes

The script handles this step automatically. See `ec2-cost-optimization.sh` for the exact CLI commands.

## Step 3: Finding unattached Elastic IPs

The script handles this step automatically. See `ec2-cost-optimization.sh` for the exact CLI commands.

## Step 4: Finding old snapshots (>90 days)

The script handles this step automatically. See `ec2-cost-optimization.sh` for the exact CLI commands.

