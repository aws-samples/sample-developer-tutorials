#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/iam-policies.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); POLICY_NAME="tut-policy-${RANDOM_ID}"; ROLE_NAME="tut-iam-role-${RANDOM_ID}"
ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::${ACCOUNT}:policy/$POLICY_NAME" 2>/dev/null; aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role"; aws iam delete-policy --policy-arn "arn:aws:iam::${ACCOUNT}:policy/$POLICY_NAME" 2>/dev/null && echo "  Deleted policy"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating a custom policy"
POLICY_ARN=$(aws iam create-policy --policy-name "$POLICY_NAME" --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject","s3:ListBucket"],"Resource":["arn:aws:s3:::example-bucket","arn:aws:s3:::example-bucket/*"]},{"Effect":"Deny","Action":"s3:DeleteObject","Resource":"*"}]}' --query 'Policy.Arn' --output text)
echo "  Policy ARN: $POLICY_ARN"
echo "Step 2: Getting policy details"
aws iam get-policy --policy-arn "$POLICY_ARN" --query 'Policy.{Name:PolicyName,Arn:Arn,Versions:AttachmentCount}' --output table
echo "Step 3: Getting policy version (the actual document)"
aws iam get-policy-version --policy-arn "$POLICY_ARN" --version-id v1 --query 'PolicyVersion.Document' --output json | python3 -m json.tool
echo "Step 4: Creating a role and attaching the policy"
aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' > /dev/null
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN"
echo "  Attached $POLICY_NAME to $ROLE_NAME"
echo "Step 5: Listing attached policies"
aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query 'AttachedPolicies[].{Name:PolicyName,Arn:PolicyArn}' --output table
echo "Step 6: Simulating policy"
aws iam simulate-principal-policy --policy-source-arn "arn:aws:iam::${ACCOUNT}:role/$ROLE_NAME" --action-names s3:GetObject s3:DeleteObject --resource-arns "arn:aws:s3:::example-bucket/file.txt" --query 'EvaluationResults[].{Action:EvalActionName,Decision:EvalDecision}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
