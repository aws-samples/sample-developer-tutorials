#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); G="tut-group-${RANDOM_ID}"
cleanup() { aws iam detach-group-policy --group-name "$G" --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess 2>/dev/null; aws iam delete-group --group-name "$G" 2>/dev/null; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating group: $G"; aws iam create-group --group-name "$G" > /dev/null
echo "Step 2: Attaching policy"; aws iam attach-group-policy --group-name "$G" --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
echo "Step 3: Describing group"; aws iam get-group --group-name "$G" --query 'Group.{Name:GroupName,Created:CreateDate}' --output table
echo "Step 4: Listing attached policies"; aws iam list-attached-group-policies --group-name "$G" --query 'AttachedPolicies[].{Name:PolicyName}' --output table
echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && cleanup
