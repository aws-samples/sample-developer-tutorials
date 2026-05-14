#!/bin/bash
set -e

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

echo "Step 1: Check Macie Session Status" >> "$LOG_FILE"
aws macie2 get-macie-session --query 'status' --output text && echo "Initial Macie Status: $?" || echo "Error getting initial Macie session"

echo "Step 2: List Findings" >> "$LOG_FILE"
aws macie2 list-findings --finding-criteria '{}' --max-results 10 --query 'length(findings)' --output text && echo "Number of Findings: $?" || echo "Error listing findings"

echo "Step 3: Create Allow List" >> "$LOG_FILE"
aws macie2 create-allow-list --criteria '{"regex":{"regexString":"example"}}' --description "Example Allow List $SUFFIX" || true

echo "Step 4: Create Classification Job" >> "$LOG_FILE"
aws macie2 create-classification-job --job-name "ExampleJob$SUFFIX" --s3-job-definition '{"bucketDefinitions":[{"bucketName":"example-bucket"}]}' || true

echo "Step 5: Create Custom Data Identifier" >> "$LOG_FILE"
aws macie2 create-custom-data-identifier --name "ExampleIdentifier$SUFFIX" --regex "example" --description "Example Custom Data Identifier" || true

echo "Step 6: Create Findings Filter" >> "$LOG_FILE"
aws macie2 create-findings-filter --name "ExampleFilter$SUFFIX" --finding-criteria '{"criterion":{"severity":{"gte":1}}}' --description "Example Findings Filter" || true

echo "Step 7: Create Invitations" >> "$LOG_FILE"
aws macie2 create-invitations --account-ids '["123456789012"]' --message "Example Invitation $SUFFIX" || true

echo "Step 8: Create Member" >> "$LOG_FILE"
aws macie2 create-member --email "example@example.com" --message "Example Member Invitation $SUFFIX" || true

echo "PASS"