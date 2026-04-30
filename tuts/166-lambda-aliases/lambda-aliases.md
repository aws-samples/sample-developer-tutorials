# Lambda Aliases

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Creating function (v1)

The script handles this step automatically. See `lambda-aliases.sh` for the exact CLI commands.

## Step 2: Creating alias pointing to v1

The script handles this step automatically. See `lambda-aliases.sh` for the exact CLI commands.

## Step 3: Deploying v2 with canary

The script handles this step automatically. See `lambda-aliases.sh` for the exact CLI commands.

## Step 4: Invoking via alias (multiple times)

The script handles this step automatically. See `lambda-aliases.sh` for the exact CLI commands.

## Step 5: Shifting all traffic to v2

The script handles this step automatically. See `lambda-aliases.sh` for the exact CLI commands.

## Cleanup

The script prompts you to clean up all created resources. If you need to clean up manually, check the script log for the resource names that were created.

