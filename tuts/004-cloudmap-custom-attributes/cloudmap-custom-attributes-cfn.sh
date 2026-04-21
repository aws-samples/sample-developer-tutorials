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

NS_ID=$(get_output NamespaceId)
TABLE=$(get_output TableName)
FUNC=$(get_output FunctionName)
echo "Namespace: $NS_ID | Table: $TABLE | Function: $FUNC"

echo ""
echo "--- Step 1: List services in namespace ---"
run_cmd aws servicediscovery list-services --filters "Name=NAMESPACE_ID,Values=$NS_ID" --query "'Services[].{Id:Id,Name:Name}'" --output table

echo ""
echo "--- Step 2: Invoke the Lambda function ---"
run_cmd aws lambda invoke --function-name "$FUNC" --cli-binary-format raw-in-base64-out --payload "'{\"action\":\"test\"}'" /tmp/cfn-resp.json
cat /tmp/cfn-resp.json && rm -f /tmp/cfn-resp.json

echo ""
echo "--- Step 3: Scan DynamoDB table ---"
run_cmd aws dynamodb scan --table-name "$TABLE" --select COUNT --query "'{Count:Count}'" --output table

echo ""
echo "Interactive steps complete."
echo "To delete stack: ./cleanup.sh $TUT_DIR"
