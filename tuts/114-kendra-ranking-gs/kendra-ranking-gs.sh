#!/bin/bash
set -e

REGION="us-east-1"
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for id in "${CREATED_RESOURCES[@]}"; do
        echo "Deleting Rescore Execution Plan with ID: $id"
        aws kendra-ranking delete-rescore-execution-plan --id "$id" || true
    done
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

NAME="test-execution-plan-${SUFFIX}"
DESCRIPTION="Test execution plan for Kendra Intelligent Ranking"
CAPACITY_UNITS='{"RescoreCapacityUnits": 1}'
CLIENT_TOKEN=$(head -c 16 /dev/urandom | base64 | tr -dc a-zA-Z0-9 | head -c 16 || true)

echo "Creating Rescore Execution Plan..." 
EXECUTION_PLAN_ID=$(aws kendra-ranking create-rescore-execution-plan \
    --name "$NAME" \
    --description "$DESCRIPTION" \
    --capacity-units "$CAPACITY_UNITS" \
    --client-token "$CLIENT_TOKEN" \
    --query 'Id' --output text)
echo "Created Rescore Execution Plan with ID: $EXECUTION_PLAN_ID" 
CREATED_RESOURCES+=("$EXECUTION_PLAN_ID")

sleep 10  # Wait for the execution plan to become active

echo "Describing Rescore Execution Plan..." 
DESCRIBE_RESPONSE=$(aws kendra-ranking describe-rescore-execution-plan \
    --id "$EXECUTION_PLAN_ID")
echo "Described Rescore Execution Plan: $DESCRIBE_RESPONSE" 

echo "Listing Rescore Execution Plans..." 
LIST_RESPONSE=$(aws kendra-ranking list-rescore-execution-plans)
echo "Listed Rescore Execution Plans: $LIST_RESPONSE" 

echo "PASS"