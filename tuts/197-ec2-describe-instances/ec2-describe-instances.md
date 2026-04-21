# Ec2 Describe Instances

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Listing all instances"; aws ec2 describe-instances --query 'Reservations[].Instances[].{Id:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[?Key==`Name`].Value|[0]}' --output table 2>/dev/null || echo "  No instances

The script handles this step automatically. See `ec2-describe-instances.sh` for the exact CLI commands.

## Step 2: Counting by state

The script handles this step automatically. See `ec2-describe-instances.sh` for the exact CLI commands.

