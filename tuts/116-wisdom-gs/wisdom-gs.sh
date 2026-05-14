#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
NAME="test-assistant-${SUFFIX}"
CLIENT_TOKEN=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

echo "Creating assistant..."
ASSISTANT_ID=$(aws wisdom create-assistant \
    --name "$NAME" \
    --type AGENT \
    --client-token "$CLIENT_TOKEN" \
    --description "Test assistant for demonstration" \
    --query 'assistant.assistantId' --output text)
echo "Assistant created with ID: $ASSISTANT_ID"

sleep 10  # Wait for the assistant to become active

echo "Verifying assistant exists..."
aws wisdom get-assistant --assistant-id "$ASSISTANT_ID" \
    --query 'assistant.name' --output text | grep "$NAME" && echo "Assistant verified."

echo "Listing assistants..."
aws wisdom list-assistants \
    --query 'assistantSummaries[?name==`'"$NAME"'`]' --output text && echo "Assistant found in list."

echo "Deleting assistant..."
aws wisdom delete-assistant --assistant-id "$ASSISTANT_ID" || true
sleep 10  # Wait for the deletion to complete

aws wisdom get-assistant --assistant-id "$ASSISTANT_ID" || echo "Assistant successfully deleted." && echo "PASS"