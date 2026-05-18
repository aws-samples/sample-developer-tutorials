#!/bin/bash
set -e

# Generate a unique suffix
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# AWS CLI commands to interact with AWS Pricing
echo "DescribeServices operation:"
aws pricing describe-services \
    --service-code AmazonEC2 \
    --format-version aws_v1 \
    --query 'ResponseMetadata.HTTPStatusCode' \
    --output text

echo "GetAttributeValues operation:"
aws pricing get-attribute-values \
    --service-code AmazonEC2 \
    --attribute-name volumeType \
    --query 'ResponseMetadata.HTTPStatusCode' \
    --output text

echo "GetProducts operation:"
aws pricing get-products \
    --service-code AmazonEC2 \
    --max-results 10 \
    --filters Type=TERM_MATCH,Field=volumeType,Value=gp2 \
    --query 'ResponseMetadata.HTTPStatusCode' \
    --output text

echo "PASS"