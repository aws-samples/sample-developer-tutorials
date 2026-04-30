# Iam Groups

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Creating group: $G"; aws iam create-group --group-name "$G

The script handles this step automatically. See `iam-groups.sh` for the exact CLI commands.

## Step 2: Attaching policy"; aws iam attach-group-policy --group-name "$G

The script handles this step automatically. See `iam-groups.sh` for the exact CLI commands.

## Step 3: Describing group"; aws iam get-group --group-name "$G

The script handles this step automatically. See `iam-groups.sh` for the exact CLI commands.

## Step 4: Listing attached policies"; aws iam list-attached-group-policies --group-name "$G

The script handles this step automatically. See `iam-groups.sh` for the exact CLI commands.

## Cleanup

The script prompts you to clean up all created resources. If you need to clean up manually, check the script log for the resource names that were created.

