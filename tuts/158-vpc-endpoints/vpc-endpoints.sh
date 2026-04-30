#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/vpc-ep.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$EP_ID" ] && aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$EP_ID" > /dev/null 2>&1 && echo "  Deleted endpoint"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Listing available VPC endpoint services"
aws ec2 describe-vpc-endpoint-services --query 'ServiceNames[:10]' --output table
echo "Step 2: Creating a gateway endpoint (S3)"
RT_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[0].RouteTableId' --output text)
EP_ID=$(aws ec2 create-vpc-endpoint --vpc-id "$VPC_ID" --service-name "com.amazonaws.${REGION}.s3" --route-table-ids "$RT_ID" --query 'VpcEndpoint.VpcEndpointId' --output text)
echo "  Endpoint: $EP_ID"
echo "Step 3: Describing endpoint"
aws ec2 describe-vpc-endpoints --vpc-endpoint-ids "$EP_ID" --query 'VpcEndpoints[0].{Id:VpcEndpointId,Service:ServiceName,State:State,Type:VpcEndpointType}' --output table
echo "Step 4: Listing endpoints"
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --query 'VpcEndpoints[].{Id:VpcEndpointId,Service:ServiceName,Type:VpcEndpointType}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
