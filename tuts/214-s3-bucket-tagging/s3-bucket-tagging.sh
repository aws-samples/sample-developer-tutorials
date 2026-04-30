#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); ACCOUNT=$(aws sts get-caller-identity --query Account --output text); B="tag-tut-${RANDOM_ID}-${ACCOUNT}"
cleanup() { aws s3 rb "s3://$B" 2>/dev/null; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating bucket"; aws s3api create-bucket --bucket "$B" > /dev/null
echo "Step 2: Adding tags"; aws s3api put-bucket-tagging --bucket "$B" --tagging 'TagSet=[{Key=Environment,Value=tutorial},{Key=Project,Value=tagging-demo},{Key=Owner,Value=tutorial-user}]'
echo "Step 3: Getting tags"; aws s3api get-bucket-tagging --bucket "$B" --query 'TagSet[].{Key:Key,Value:Value}' --output table
echo "Step 4: Deleting tags"; aws s3api delete-bucket-tagging --bucket "$B"; echo "  Tags deleted"
echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && cleanup
