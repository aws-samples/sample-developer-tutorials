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

INSTANCE=$(get_output InstanceName)
DISK=$(get_output DiskName)
echo "Instance: $INSTANCE"
echo "Disk: $DISK"

echo ""
echo "--- Step 1: Get instance state ---"
run_cmd aws lightsail get-instance-state --instance-name "$INSTANCE"

echo ""
echo "--- Step 2: Get instance details ---"
run_cmd aws lightsail get-instance --instance-name "$INSTANCE" --query "'instance.{name:name,blueprint:blueprintId,bundle:bundleId,state:state.name,ip:publicIpAddress}'" --output table

echo ""
echo "--- Step 3: Create a snapshot ---"
SNAP_NAME="${INSTANCE}-snapshot"
run_cmd aws lightsail create-instance-snapshot --instance-name "$INSTANCE" --instance-snapshot-name "$SNAP_NAME"

echo ""
echo "--- Step 4: Delete the snapshot ---"
sleep 10
run_cmd aws lightsail delete-instance-snapshot --instance-snapshot-name "$SNAP_NAME"

echo ""
echo "Interactive steps complete."
echo "To delete stack: ./cleanup.sh $TUT_DIR"
