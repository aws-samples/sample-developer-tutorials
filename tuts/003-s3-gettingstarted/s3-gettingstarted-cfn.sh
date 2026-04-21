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

BUCKET=$(get_output BucketName)
echo "Bucket: $BUCKET"

echo ""
echo "--- Step 1: Upload an object ---"
echo "Hello from the S3 tutorial" > /tmp/s3-tut-test.txt
run_cmd aws s3 cp /tmp/s3-tut-test.txt "s3://$BUCKET/tutorial/hello.txt"

echo ""
echo "--- Step 2: List objects ---"
run_cmd aws s3api list-objects-v2 --bucket "$BUCKET" --prefix tutorial/ --query "'Contents[].{Key:Key,Size:Size}'" --output table

echo ""
echo "--- Step 3: Download the object ---"
run_cmd aws s3 cp "s3://$BUCKET/tutorial/hello.txt" /tmp/s3-tut-download.txt
echo "Content: $(cat /tmp/s3-tut-download.txt)"

echo ""
echo "--- Step 4: Copy the object ---"
run_cmd aws s3 cp "s3://$BUCKET/tutorial/hello.txt" "s3://$BUCKET/tutorial/backup/hello.txt"

echo ""
echo "--- Step 5: List all objects ---"
run_cmd aws s3api list-objects-v2 --bucket "$BUCKET" --prefix tutorial/ --query "'Contents[].Key'" --output table

echo ""
echo "--- Step 6: Clean up tutorial objects ---"
run_cmd aws s3 rm "s3://$BUCKET/tutorial/" --recursive
rm -f /tmp/s3-tut-test.txt /tmp/s3-tut-download.txt
echo "Bucket remains for other tutorials."
