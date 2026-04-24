#!/bin/bash
# Delete a tutorial's CloudFormation stack and optionally clean up prerequisites.
# Usage: ./cleanup.sh <tutorial-dir>
#        ./cleanup.sh --prereqs          # delete prerequisite stacks
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TUTS_DIR="$REPO_ROOT/tuts"
PREREQ_STACK="tutorial-prereqs"

if [ "$1" = "--prereqs" ]; then
    echo "=== Prerequisite stacks ==="
    for STACK in $(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
        --query "StackSummaries[?starts_with(StackName, '$PREREQ_STACK')].StackName" --output text 2>/dev/null); do
        echo "  $STACK"
    done

    echo ""
    echo "Prerequisite stacks are shared across tutorials."
    echo "Only delete them when you're done with all tutorials."
    read -rp "Delete all prerequisite stacks? (y/n): " CHOICE
    [[ ! "$CHOICE" =~ ^[Yy]$ ]] && exit 0

    # Handle bucket prereq — must empty first
    BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name "$PREREQ_STACK-bucket" \
        --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text 2>/dev/null)
    if [ -n "$BUCKET_NAME" ] && [ "$BUCKET_NAME" != "None" ]; then
        OBJ_COUNT=$(aws s3api list-objects-v2 --bucket "$BUCKET_NAME" --query 'KeyCount' --output text 2>/dev/null || echo "0")
        if [ "$OBJ_COUNT" -gt 0 ] 2>/dev/null; then
            echo ""
            echo "Bucket $BUCKET_NAME contains $OBJ_COUNT objects."
            read -rp "Empty the bucket? (y/n): " EMPTY
            if [[ "$EMPTY" =~ ^[Yy]$ ]]; then
                echo "Emptying bucket..."
                aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet
                aws s3api list-object-versions --bucket "$BUCKET_NAME" \
                    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}, Quiet: true}' \
                    --output json 2>/dev/null | \
                    aws s3api delete-objects --bucket "$BUCKET_NAME" --delete file:///dev/stdin > /dev/null 2>&1 || true
                echo "  Emptied"
            else
                echo "Cannot delete bucket stack while bucket has objects."
                exit 1
            fi
        fi
        aws cloudformation delete-stack --stack-name "$PREREQ_STACK-bucket"
        echo "Deleting $PREREQ_STACK-bucket..."
        aws cloudformation wait stack-delete-complete --stack-name "$PREREQ_STACK-bucket" 2>/dev/null
        echo "  Deleted"
    fi

    # Handle VPC prereqs — delete cleanly unless tutorial stacks still reference them
    for VPC_TYPE in vpc-public vpc-private; do
        VPC_STACK="$PREREQ_STACK-$VPC_TYPE"
        STATUS=$(aws cloudformation describe-stacks --stack-name "$VPC_STACK" --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "NONE")
        if [ "$STATUS" != "NONE" ] && [ "$STATUS" != "DELETE_COMPLETE" ]; then
            echo "Deleting $VPC_STACK..."
            aws cloudformation delete-stack --stack-name "$VPC_STACK"
            aws cloudformation wait stack-delete-complete --stack-name "$VPC_STACK" 2>/dev/null && echo "  Deleted" || echo "  Failed (other stacks may still import from it)"
        fi
    done
    exit 0
fi

# Delete a tutorial stack
TUT_DIR="$1"
[ -z "$TUT_DIR" ] && echo "Usage: $0 <tutorial-dir> | --prereqs" && exit 1

# Prereq tutorials have their own cleanup scripts
if [[ "$TUT_DIR" == 000-prereqs-* ]]; then
    CLEANUP_SCRIPT="$TUTS_DIR/$TUT_DIR/$(ls "$TUTS_DIR/$TUT_DIR/" | grep cleanup | head -1)"
    if [ -f "$CLEANUP_SCRIPT" ]; then
        echo "Running prereq cleanup: $CLEANUP_SCRIPT"
        bash "$CLEANUP_SCRIPT"
        exit $?
    fi
fi

STACK_NAME="tutorial-$(echo "$TUT_DIR" | sed 's/^[0-9]*-//')"

# Check if stack exists
STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "NONE")

if [ "$STATUS" = "NONE" ] || [ "$STATUS" = "DELETE_COMPLETE" ]; then
    echo "Stack $STACK_NAME does not exist."
    echo ""
    echo "Searching for leftover resources tagged with this stack name..."
    echo "(Resources that may have been left behind from a failed deletion)"
    echo ""
    # Search by tag
    aws resourcegroupstaggingapi get-resources \
        --tag-filters "Key=tutorial,Values=$STACK_NAME" \
        --query 'ResourceTagMappingList[].{ARN:ResourceARN}' --output table 2>/dev/null || true
    # Also search by name prefix
    aws resourcegroupstaggingapi get-resources \
        --tag-filters "Key=aws:cloudformation:stack-name,Values=$STACK_NAME" \
        --query 'ResourceTagMappingList[].{ARN:ResourceARN}' --output table 2>/dev/null || true
    exit 0
fi

echo "Stack: $STACK_NAME (status: $STATUS)"
echo ""
echo "=== Stack Resources ==="
aws cloudformation list-stack-resources --stack-name "$STACK_NAME" \
    --query 'StackResourceSummaries[].{Type:ResourceType,LogicalId:LogicalResourceId,PhysicalId:PhysicalResourceId,Status:ResourceStatus}' --output table

echo ""
echo "=== Stack Outputs ==="
aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}' --output table 2>/dev/null || echo "  (none)"

echo ""
read -rp "Delete stack $STACK_NAME? (y/n): " CHOICE
[[ ! "$CHOICE" =~ ^[Yy]$ ]] && exit 0

echo "Deleting..."
aws cloudformation delete-stack --stack-name "$STACK_NAME"
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"
echo "Stack $STACK_NAME deleted."

echo ""
echo "Note: Prerequisite stacks are still running. To delete them:"
echo "  $0 --prereqs"
