#!/bin/bash
set -e

echo "=== AWS Macie Tutorial ==="
echo "This tutorial demonstrates how to use AWS Macie to manage sensitive data in your AWS environment."
echo "We will cover checking session status, listing findings, creating allow lists, classification jobs, custom data identifiers, findings filters, invitations, and members."

if [ -t 1 ]; then 
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
  for resource in "${CREATED_RESOURCES[@]}"; do
    aws macie2 delete-$resource --resource-id "$resource" || true
  done
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "=== Step 1: Check Macie Session Status ==="
echo "Checking the status of your Macie session is important to ensure that the service is enabled and running."
echo "This step verifies that Macie is active and ready for further operations."
aws_macie_status=$(aws macie2 get-macie-session --query 'status' --output text)
echo "Result: Initial Macie Status: $aws_macie_status"
echo ""

echo "=== Step 2: List Findings ==="
echo "Listing findings helps you understand the current security posture of your data in AWS."
echo "This step retrieves a list of findings to show the number of security issues detected by Macie."
number_of_findings=$(aws macie2 list-findings --finding-criteria '{}' --max-results 10 --query 'length(findings)' --output text)
echo "Result: Number of Findings: $number_of_findings"
echo ""

echo "=== Step 3: Create Allow List ==="
echo "An allow list helps Macie ignore specific data patterns that are known to be safe."
echo "This step creates an allow list to exclude certain regex patterns from Macie scans."
allow_list_response=$(aws macie2 create-allow-list --criteria '{"regex":{"regexString":"example"}}' --description "Example Allow List $SUFFIX")
allow_list_id=$(echo "$allow_list_response" | jq -r '.id')
aws macie2 tag-resource --resource-arn "arn:aws:macie2:us-east-1:123456789012:allow-list/$allow_list_id" --tags Key=project,Value=doc-smith Key=tutorial,Value=macie2-gs
echo "Result: Allow List Created"
CREATED_RESOURCES+=("allow-list")
echo ""

echo "=== Step 4: Create Classification Job ==="
echo "A classification job scans your S3 buckets for sensitive data and generates findings."
echo "This step creates a classification job to scan a specified S3 bucket for sensitive data."
classification_job_response=$(aws macie2 create-classification-job --job-name "ExampleJob$SUFFIX" --s3-job-definition '{"bucketDefinitions":[{"bucketName":"example-bucket"}]}' --query 'jobId' --output text)
aws macie2 tag-resource --resource-arn "arn:aws:macie2:us-east-1:123456789012:classification-job/$classification_job_response" --tags Key=project,Value=doc-smith Key=tutorial,Value=macie2-gs
echo "Result: Classification Job Created with ID: $classification_job_response"
CREATED_RESOURCES+=("classification-job")
echo ""

echo "=== Step 5: Create Custom Data Identifier ==="
echo "A custom data identifier allows you to define specific patterns of sensitive data that Macie should detect."
echo "This step creates a custom data identifier to recognize a specific regex pattern in your data."
custom_data_identifier_response=$(aws macie2 create-custom-data-identifier --name "ExampleIdentifier$SUFFIX" --regex "example" --description "Example Custom Data Identifier" --query 'id' --output text)
aws macie2 tag-resource --resource-arn "arn:aws:macie2:us-east-1:123456789012:custom-data-identifier/$custom_data_identifier_response" --tags Key=project,Value=doc-smith Key=tutorial,Value=macie2-gs
echo "Result: Custom Data Identifier Created with ID: $custom_data_identifier_response"
CREATED_RESOURCES+=("custom-data-identifier")
echo ""
fi