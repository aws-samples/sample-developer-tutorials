#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing security groups"; aws ec2 describe-security-groups --query 'SecurityGroups[:10].{Id:GroupId,Name:GroupName,VPC:VpcId,InRules:IpPermissions|length(@),OutRules:IpPermissionsEgress|length(@)}' --output table
echo "Step 2: Finding groups with open SSH"
aws ec2 describe-security-groups --filters "Name=ip-permission.from-port,Values=22" "Name=ip-permission.cidr,Values=0.0.0.0/0" --query 'SecurityGroups[].{Id:GroupId,Name:GroupName}' --output table 2>/dev/null || echo "  No groups with open SSH"
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
