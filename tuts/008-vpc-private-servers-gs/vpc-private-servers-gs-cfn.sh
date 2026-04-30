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
        "$REPO_ROOT/cfn/deploy.sh" "$TUT_DIR"
    else
        echo "Cannot proceed without the stack. Deploy with: ./deploy.sh $TUT_DIR"
        exit 1
    fi
fi
echo "Stack: $STACK_NAME ($STATUS)"

VPC_ID=$(get_output VpcId)
ASG=$(get_output ASGName)
echo "VPC: $VPC_ID | ASG: $ASG"

echo ""
echo "--- Step 1: Describe Auto Scaling group ---"
run_cmd aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG" --query "'AutoScalingGroups[0].{Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Instances:Instances|length(@)}'" --output table

echo ""
echo "--- Step 2: Check NAT gateway ---"
run_cmd aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "'NatGateways[0].{Id:NatGatewayId,State:State,IP:NatGatewayAddresses[0].PublicIp}'" --output table

echo ""
echo "Interactive steps complete."
echo "To delete stack: ./cleanup.sh $TUT_DIR"
