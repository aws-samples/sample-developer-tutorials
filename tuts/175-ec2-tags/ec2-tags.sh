#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tags.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
SG_ID=$(aws ec2 create-security-group --group-name "tut-tags-${RANDOM_ID}" --description "Tag tutorial" --vpc-id "$VPC_ID" --query 'GroupId' --output text)
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws ec2 delete-security-group --group-id "$SG_ID" 2>/dev/null && echo "  Deleted SG"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Adding tags"
aws ec2 create-tags --resources "$SG_ID" --tags Key=Environment,Value=tutorial Key=Project,Value=tag-demo Key=Owner,Value=tutorial-user Key=CostCenter,Value=12345
echo "  Added 4 tags to $SG_ID"
echo "Step 2: Describing tags"
aws ec2 describe-tags --filters "Name=resource-id,Values=$SG_ID" --query 'Tags[].{Key:Key,Value:Value}' --output table
echo "Step 3: Finding resources by tag"
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=tag-demo" --query 'SecurityGroups[].{Id:GroupId,Name:GroupName}' --output table
echo "Step 4: Removing a tag"
aws ec2 delete-tags --resources "$SG_ID" --tags Key=CostCenter
echo "  Removed CostCenter tag"
aws ec2 describe-tags --filters "Name=resource-id,Values=$SG_ID" --query 'Tags[].{Key:Key,Value:Value}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
