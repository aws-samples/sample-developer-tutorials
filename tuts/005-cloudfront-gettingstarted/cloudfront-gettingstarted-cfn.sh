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

DOMAIN=$(get_output DistributionDomain)
BUCKET=$(get_output BucketName)
echo "Distribution: $DOMAIN | Bucket: $BUCKET"

echo ""
echo "--- Step 1: Upload content to origin ---"
echo "<html><body><h1>Hello from CloudFront</h1></body></html>" > /tmp/cf-index.html
run_cmd aws s3 cp /tmp/cf-index.html "s3://$BUCKET/index.html" --content-type text/html

echo ""
echo "--- Step 2: Access via CloudFront ---"
echo "URL: https://$DOMAIN/index.html"
run_cmd curl -s --max-time 10 "https://$DOMAIN/index.html"

echo ""
echo "--- Step 3: Clean up content ---"
run_cmd aws s3 rm "s3://$BUCKET/index.html"
rm -f /tmp/cf-index.html

echo ""
echo "Interactive steps complete."
echo "To delete stack: ./cleanup.sh $TUT_DIR"
