#!/bin/bash
# Deploy a tutorial's CloudFormation stack, creating prerequisites if needed.
# Usage: ./deploy.sh <tutorial-dir> [param=value ...]
# Example: ./deploy.sh 094-aws-cloudtrail-gs
#          ./deploy.sh 026-kinesis-data-streams Runtime=python3.12
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TUTS_DIR="$REPO_ROOT/tuts"
PREREQ_STACK="tutorial-prereqs"

usage() {
    echo "Usage: $0 <tutorial-dir> [param=value ...]"
    echo ""
    echo "Tutorials with CloudFormation templates:"
    for dir in "$TUTS_DIR"/*/; do
        TEMPLATE=$(find "$dir" -name 'cfn-*.yaml' -o -name 'cfn-*.yml' 2>/dev/null | head -1)
        [ -n "$TEMPLATE" ] && echo "  $(basename "$dir")"
    done
    exit 0
}

[ $# -lt 1 ] && usage

TUT_DIR="$1"
shift
OVERRIDES="$@"

# Prereq tutorials have their own deploy scripts
if [[ "$TUT_DIR" == 000-prereqs-* ]]; then
    DEPLOY_SCRIPT="$TUTS_DIR/$TUT_DIR/$(ls "$TUTS_DIR/$TUT_DIR/" | grep -v cleanup | grep -v cfn | grep -v README | grep -v REVISION | grep '\.sh$' | head -1)"
    if [ -f "$DEPLOY_SCRIPT" ]; then
        echo "Running prereq deploy script: $DEPLOY_SCRIPT"
        bash "$DEPLOY_SCRIPT"
        exit $?
    fi
fi

# Find the template
TEMPLATE=$(find "$TUTS_DIR/$TUT_DIR" -name 'cfn-*.yaml' -o -name 'cfn-*.yml' 2>/dev/null | head -1)
if [ -z "$TEMPLATE" ]; then
    echo "No CloudFormation template found in tuts/$TUT_DIR/"
    echo "Looking for files matching cfn-*.yaml"
    exit 1
fi

STACK_NAME="tutorial-$(echo "$TUT_DIR" | sed 's/^[0-9]*-//')"
echo "Template: $TEMPLATE"
echo "Stack:    $STACK_NAME"

# Check if the template imports from prerequisite stacks
TEMPLATE_CONTENT=$(cat "$TEMPLATE")
NEEDS_BUCKET=false
NEEDS_VPC=false

if echo "$TEMPLATE_CONTENT" | grep -q "Fn::ImportValue.*prereqs.*BucketName\|prereq-bucket"; then
    NEEDS_BUCKET=true
fi
if echo "$TEMPLATE_CONTENT" | grep -q "Fn::ImportValue.*prereqs-vpc-public\|prereq-vpc-public"; then
    NEEDS_VPC=true
    VPC_TYPE="public"
fi
if echo "$TEMPLATE_CONTENT" | grep -q "Fn::ImportValue.*prereqs-vpc-private\|prereq-vpc-private"; then
    NEEDS_VPC=true
    VPC_TYPE="private"
fi

# Deploy prerequisites if needed
if [ "$NEEDS_BUCKET" = true ]; then
    echo ""
    echo "This tutorial requires a shared S3 bucket."
    BUCKET_STACK=$(aws cloudformation describe-stacks --stack-name "$PREREQ_STACK-bucket" --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "NONE")
    if [ "$BUCKET_STACK" = "NONE" ] || [ "$BUCKET_STACK" = "DELETE_COMPLETE" ]; then
        echo "Prerequisite stack '$PREREQ_STACK-bucket' not found."
        read -rp "Create it now? (y/n): " CHOICE
        if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
            echo "Creating shared bucket..."
            aws cloudformation deploy \
                --template-file "$CFN_DIR/prereq-bucket.yaml" \
                --stack-name "$PREREQ_STACK-bucket"
            echo "Bucket created: $(aws cloudformation describe-stacks --stack-name "$PREREQ_STACK-bucket" --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text)"
        else
            echo "Cannot proceed without the bucket prerequisite."
            exit 1
        fi
    else
        BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name "$PREREQ_STACK-bucket" --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text)
        echo "Using existing bucket: $BUCKET_NAME"
    fi
fi

if [ "$NEEDS_VPC" = true ]; then
    echo ""
    VPC_STACK_NAME="$PREREQ_STACK-vpc-$VPC_TYPE"
    echo "This tutorial requires a VPC ($VPC_TYPE subnets)."
    VPC_STACK=$(aws cloudformation describe-stacks --stack-name "$VPC_STACK_NAME" --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "NONE")
    if [ "$VPC_STACK" = "NONE" ] || [ "$VPC_STACK" = "DELETE_COMPLETE" ]; then
        echo "Prerequisite stack '$VPC_STACK_NAME' not found."
        read -rp "Create it now? (y/n): " CHOICE
        if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
            echo "Creating VPC ($VPC_TYPE)..."
            aws cloudformation deploy \
                --template-file "$CFN_DIR/prereq-vpc-$VPC_TYPE.yaml" \
                --stack-name "$VPC_STACK_NAME"
            echo "VPC created: $(aws cloudformation describe-stacks --stack-name "$VPC_STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' --output text)"
        else
            echo "Cannot proceed without the VPC prerequisite."
            exit 1
        fi
    else
        VPC_ID=$(aws cloudformation describe-stacks --stack-name "$VPC_STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' --output text)
        echo "Using existing VPC: $VPC_ID"
    fi
fi

# Build capabilities argument
CAPA_ARG=""
if echo "$TEMPLATE_CONTENT" | grep -qE "AWS::IAM::Role|AWS::IAM::Policy|AWS::IAM::InstanceProfile"; then
    CAPA_ARG="--capabilities CAPABILITY_IAM"
fi
if echo "$TEMPLATE_CONTENT" | grep -q "RoleName\|PolicyName"; then
    CAPA_ARG="--capabilities CAPABILITY_NAMED_IAM"
fi

# Build overrides argument
OVERRIDES_ARG=""
if [ -n "$OVERRIDES" ]; then
    OVERRIDES_ARG="--parameter-overrides $OVERRIDES"
fi

# Deploy
echo ""
echo "Deploying stack: $STACK_NAME"
aws cloudformation deploy \
    --template-file "$TEMPLATE" \
    --stack-name "$STACK_NAME" \
    $CAPA_ARG \
    $OVERRIDES_ARG \
    --no-fail-on-empty-changeset

echo ""
echo "=== Stack Resources ==="
aws cloudformation list-stack-resources --stack-name "$STACK_NAME" \
    --query 'StackResourceSummaries[].{Type:ResourceType,LogicalId:LogicalResourceId,PhysicalId:PhysicalResourceId,Status:ResourceStatus}' --output table 2>/dev/null || echo "  (none)"

echo ""
echo "=== Stack Outputs ==="
aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}' --output table 2>/dev/null || echo "  (none)"

echo ""
echo "To delete: ./cleanup.sh $TUT_DIR"
