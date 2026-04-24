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

IPAM_ID=$(get_output IpamId)
POOL_ID=$(get_output PoolId)
echo "IPAM: $IPAM_ID | Pool: $POOL_ID"

echo ""
echo "--- Step 1: Describe the IPAM ---"
run_cmd aws ec2 describe-ipams --ipam-ids "$IPAM_ID" --query "'Ipams[0].{Id:IpamId,Region:IpamRegion}'" --output table

echo ""
echo "--- Step 2: Get pool CIDRs ---"
run_cmd aws ec2 get-ipam-pool-cidrs --ipam-pool-id "$POOL_ID" --query "'IpamPoolCidrs[].{Cidr:Cidr,State:State}'" --output table

echo ""
echo "Interactive steps complete."
echo "To delete stack: ./cleanup.sh $TUT_DIR"
