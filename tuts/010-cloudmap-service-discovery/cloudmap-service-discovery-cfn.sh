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

NS_ID=$(get_output NamespaceId)
SVC_ID=$(get_output ServiceId)
echo "Namespace: $NS_ID | Service: $SVC_ID"

echo ""
echo "--- Step 1: Register an instance ---"
INST_ID="i-$(openssl rand -hex 4)"
run_cmd aws servicediscovery register-instance --service-id "$SVC_ID" --instance-id "$INST_ID" --attributes AWS_INSTANCE_IPV4=10.0.0.1

echo ""
echo "--- Step 2: List instances ---"
run_cmd aws servicediscovery list-instances --service-id "$SVC_ID" --query "'Instances[].{Id:Id,IP:Attributes.AWS_INSTANCE_IPV4}'" --output table

echo ""
echo "--- Step 3: Deregister the instance ---"
run_cmd aws servicediscovery deregister-instance --service-id "$SVC_ID" --instance-id "$INST_ID"

echo ""
echo "Interactive steps complete."
echo "To delete stack: ./cleanup.sh $TUT_DIR"
