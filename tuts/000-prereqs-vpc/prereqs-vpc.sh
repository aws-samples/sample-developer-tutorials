#!/bin/bash
# Deploy the shared VPC prereq stacks
set -eo pipefail

echo "Deploying public VPC stack (public + private subnets, NAT gateway)..."
aws cloudformation deploy \
    --template-file "$(dirname "$0")/cfn-prereqs-vpc-public.yaml" \
    --stack-name tutorial-prereqs-vpc-public \
    --capabilities CAPABILITY_IAM

echo ""
echo "Stack outputs:"
aws cloudformation describe-stacks --stack-name tutorial-prereqs-vpc-public \
    --query 'Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}' --output table

echo ""
echo "Done. Tutorials that need a VPC will use this stack automatically."
