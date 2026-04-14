#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/sso.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing IAM Identity Center instances"
INSTANCE_ARN=$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text 2>/dev/null)
if [ -z "$INSTANCE_ARN" ] || [ "$INSTANCE_ARN" = "None" ]; then echo "  No IAM Identity Center instance found. Enable it in the console first."; rm -rf "$WORK_DIR"; exit 0; fi
echo "  Instance: $INSTANCE_ARN"
echo "Step 2: Listing permission sets"
aws sso-admin list-permission-sets --instance-arn "$INSTANCE_ARN" --query 'PermissionSets[:5]' --output table 2>/dev/null || echo "  No permission sets"
echo "Step 3: Listing accounts for provisioned permission sets"
aws sso-admin list-accounts-for-provisioned-permission-set --instance-arn "$INSTANCE_ARN" --permission-set-arn "$(aws sso-admin list-permission-sets --instance-arn "$INSTANCE_ARN" --query 'PermissionSets[0]' --output text 2>/dev/null)" --query 'AccountIds' --output table 2>/dev/null || echo "  No provisioned accounts"
echo ""; echo "Tutorial complete. No resources created — read-only."
rm -rf "$WORK_DIR"
