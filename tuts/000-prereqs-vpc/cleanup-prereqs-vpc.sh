#!/bin/bash
set -eo pipefail
echo "Deleting VPC prereq stacks..."
for STACK in tutorial-prereqs-vpc-public tutorial-prereqs-vpc-private; do
    if aws cloudformation describe-stacks --stack-name "$STACK" > /dev/null 2>&1; then
        aws cloudformation delete-stack --stack-name "$STACK"
        echo "  Deleting $STACK..."
        aws cloudformation wait stack-delete-complete --stack-name "$STACK"
        echo "  ✓ $STACK deleted"
    fi
done
echo "Done."
