#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/fis.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); ROLE_NAME="fis-tut-role-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$TEMPLATE_ID" ] && aws fis delete-experiment-template --id "$TEMPLATE_ID" > /dev/null 2>&1 && echo "  Deleted template"; aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name fis-policy 2>/dev/null; aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating IAM role"
ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"fis.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query 'Role.Arn' --output text)
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name fis-policy --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["ec2:DescribeInstances","ec2:StopInstances","ec2:StartInstances"],"Resource":"*"}]}'
echo "  Role: $ROLE_ARN"; sleep 10
echo "Step 2: Listing available actions"
aws fis list-actions --query 'actions[:5].{Id:id,Description:description}' --output table
echo "Step 3: Creating experiment template"
TEMPLATE_ID=$(aws fis create-experiment-template --description "Tutorial: stop EC2 instance" --role-arn "$ROLE_ARN" --stop-conditions '[{"source":"none"}]' --actions '{"stopInstances":{"actionId":"aws:ec2:stop-instances","parameters":{"startInstancesAfterDuration":"PT1M"},"targets":{"Instances":"tutorialInstances"}}}' --targets '{"tutorialInstances":{"resourceType":"aws:ec2:instance","selectionMode":"COUNT(1)","resourceTags":{"tutorial":"fis-test"}}}' --query 'experimentTemplate.id' --output text)
echo "  Template ID: $TEMPLATE_ID"
echo "Step 4: Describing template"
aws fis get-experiment-template --id "$TEMPLATE_ID" --query 'experimentTemplate.{Id:id,Description:description,Actions:actions|length(@),Targets:targets|length(@)}' --output table
echo "Step 5: Listing templates"
aws fis list-experiment-templates --query 'experimentTemplates[?starts_with(id, `EXT`)].{Id:id,Description:description}' --output table
echo "  (Not starting experiment — would require tagged EC2 instances)"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
