#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Getting current password policy"
aws iam get-account-password-policy --query 'PasswordPolicy.{MinLength:MinimumPasswordLength,RequireUpper:RequireUppercaseCharacters,RequireLower:RequireLowercaseCharacters,RequireNumbers:RequireNumbers,RequireSymbols:RequireSymbols,MaxAge:MaxPasswordAge,ExpirePasswords:ExpirePasswords}' --output table 2>/dev/null || echo "  No custom password policy set"
echo "Step 2: Getting account authorization details summary"
aws iam get-account-summary --query 'SummaryMap.{Users:Users,Groups:Groups,Roles:Roles,Policies:Policies,MFADevices:MFADevices}' --output table
echo "Step 3: Listing access keys"
aws iam list-access-keys --query 'AccessKeyMetadata[].{User:UserName,KeyId:AccessKeyId,Status:Status,Created:CreateDate}' --output table
echo ""; echo "Tutorial complete. No resources created — read-only."
rm -rf "$WORK_DIR"
