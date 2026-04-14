#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing MFA devices"
aws iam list-mfa-devices --query 'MFADevices[].{User:UserName,Serial:SerialNumber,Enabled:EnableDate}' --output table 2>/dev/null || echo "  No MFA devices"
echo "Step 2: Listing virtual MFA devices"
aws iam list-virtual-mfa-devices --query 'VirtualMFADevices[:5].{Serial:SerialNumber,User:User.UserName}' --output table
echo "Step 3: Getting account summary (MFA status)"
aws iam get-account-summary --query 'SummaryMap.{Users:Users,MFADevices:MFADevices,AccountMFAEnabled:AccountMFAEnabled}' --output table
echo "Step 4: Getting credential report"
aws iam generate-credential-report > /dev/null 2>&1; sleep 3
aws iam get-credential-report --query 'GeneratedTime' --output text 2>/dev/null || echo "  Report generating..."
echo ""; echo "Tutorial complete. No resources created — read-only."
rm -rf "$WORK_DIR"
