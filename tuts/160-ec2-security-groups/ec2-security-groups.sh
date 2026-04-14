#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/sg.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); SG_NAME="tut-sg-${RANDOM_ID}"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$SG_ID" ] && aws ec2 delete-security-group --group-id "$SG_ID" 2>/dev/null && echo "  Deleted security group"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating security group: $SG_NAME"
SG_ID=$(aws ec2 create-security-group --group-name "$SG_NAME" --description "Tutorial security group" --vpc-id "$VPC_ID" --query 'GroupId' --output text)
echo "  SG ID: $SG_ID"
echo "Step 2: Adding inbound rules"
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 10.0.0.0/8 > /dev/null
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null
echo "  Added SSH (10.0.0.0/8), HTTP, HTTPS rules"
echo "Step 3: Describing rules"
aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$SG_ID" --query 'SecurityGroupRules[?!IsEgress].{Port:FromPort,Protocol:IpProtocol,CIDR:CidrIpv4}' --output table
echo "Step 4: Adding a tag"
aws ec2 create-tags --resources "$SG_ID" --tags Key=Environment,Value=tutorial
echo "Step 5: Listing security groups"
aws ec2 describe-security-groups --group-ids "$SG_ID" --query 'SecurityGroups[0].{Name:GroupName,Id:GroupId,InboundRules:IpPermissions|length(@)}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
