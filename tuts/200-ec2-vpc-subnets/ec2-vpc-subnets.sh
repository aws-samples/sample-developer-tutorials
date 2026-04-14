#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing VPCs"; aws ec2 describe-vpcs --query 'Vpcs[].{Id:VpcId,CIDR:CidrBlock,Default:IsDefault}' --output table
echo "Step 2: Listing subnets"; aws ec2 describe-subnets --query 'Subnets[:10].{Id:SubnetId,VPC:VpcId,AZ:AvailabilityZone,CIDR:CidrBlock}' --output table
echo "Step 3: Listing route tables"; aws ec2 describe-route-tables --query 'RouteTables[:5].{Id:RouteTableId,VPC:VpcId,Routes:Routes|length(@)}' --output table
echo "Step 4: Listing internet gateways"; aws ec2 describe-internet-gateways --query 'InternetGateways[:5].{Id:InternetGatewayId,VPC:Attachments[0].VpcId}' --output table
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
