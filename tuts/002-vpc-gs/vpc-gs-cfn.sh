#!/bin/bash
# Run the interactive tutorial steps against resources created by CloudFormation.
# If the stack does not exist, offers to deploy it first.
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TUT_DIR="$(basename "$SCRIPT_DIR")"
STACK_NAME="tutorial-$(echo "$TUT_DIR" | sed 's/^[0-9]*-//')"

get_output() { aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey==\`$1\`].OutputValue" --output text 2>/dev/null; }

run_cmd() {
    echo ""
    echo "$ $@"
    eval "$@"
}

# Check if stack exists, offer to create
STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "NONE")
if [ "$STATUS" = "NONE" ] || [ "$STATUS" = "DELETE_COMPLETE" ]; then
    echo "Stack $STACK_NAME does not exist."
    read -rp "Deploy it now? (y/n): " CHOICE
    if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
        "$REPO_ROOT/deploy.sh" "$TUT_DIR"
    else
        echo "Cannot proceed without the stack. Deploy with: ./deploy.sh $TUT_DIR"
        exit 1
    fi
fi
echo "Stack: $STACK_NAME ($STATUS)"

VPC_ID=$(get_output VpcId)
INSTANCE_ID=$(get_output InstanceId)
PUBLIC_IP=$(get_output PublicIp)
echo "VPC: $VPC_ID | Instance: $INSTANCE_ID | IP: $PUBLIC_IP"

echo ""
echo "--- Step 1: Describe the VPC ---"
run_cmd aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query "'Vpcs[0].{VpcId:VpcId,CIDR:CidrBlock,State:State}'" --output table

echo ""
echo "--- Step 2: List subnets ---"
run_cmd aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "'Subnets[].{Id:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone}'" --output table

echo ""
echo "--- Step 3: Check instance status ---"
run_cmd aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "'Reservations[0].Instances[0].{State:State.Name,Type:InstanceType,IP:PublicIpAddress}'" --output table

echo ""
echo "Interactive steps complete."
echo "To delete stack: ./cleanup.sh $TUT_DIR"
