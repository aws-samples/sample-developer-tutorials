#!/bin/bash
set -e

# Generate a random suffix
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Create a temporary directory and clean up on exit
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Table name with unique suffix
TABLE_NAME="example-table-${SUFFIX}"

# Create DynamoDB table
aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --key-schema AttributeName=id,KeyType=HASH \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Wait for the table to be active
aws dynamodb wait table-exists --table-name "$TABLE_NAME"

# Enable streams on the table
aws dynamodb update-table \
    --table-name "$TABLE_NAME" \
    --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES

# List all streams and get the first stream ARN
STREAM_ARN=$(aws dynamodb list-tables --query 'TableNames[0]' --output text)

# Describe the stream
aws dynamodb describe-table --table-name "$TABLE_NAME"

echo "PASS"