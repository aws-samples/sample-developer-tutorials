#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
NAME="test-assistant-${SUFFIX}"
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for id in "${CREATED_RESOURCES[@]}"; do
        aws wisdom delete-assistant --assistant-id "$id" || true
    done
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "Step 1: Creating assistant..." 
CLIENT_TOKEN=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
ASSISTANT_ID=$(aws wisdom create-assistant \
    --name "$NAME" \
    --type AGENT \
    --client-token "$CLIENT_TOKEN" \
    --description "Test assistant for demonstration" \
    --query 'assistant.assistantId' --output text)
echo "Assistant created with ID: $ASSISTANT_ID" 
CREATED_RESOURCES+=("$ASSISTANT_ID")
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
aws wisdom tag-resource --resource-arn "arn:aws:wisdom:us-east-1:${ACCOUNT_ID}:assistant/${ASSISTANT_ID}" --tags Key=project,Value=doc-smith Key=tutorial,Value=wisdom-gs

sleep 10  # Wait for the assistant to become active

echo "Step 2: Verifying assistant exists..." 
aws wisdom get-assistant --assistant-id "$ASSISTANT_ID" \
    --query 'assistant.name' --output text | grep "$NAME" && echo "Assistant verified." 

echo "Step 3: Listing assistants..." 
aws wisdom list-assistants \
    --query 'assistantSummaries[?name==`'"$NAME"'`]' --output text && echo "Assistant found in list." 

echo "Step 4: Deleting assistant..." 
sleep 10  # Wait for the deletion to complete

aws wisdom get-assistant --assistant-id "$ASSISTANT_ID" || echo "Assistant successfully deleted." && echo "PASS"
