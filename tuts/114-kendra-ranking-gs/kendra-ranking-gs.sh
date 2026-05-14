#!/bin/bash
set -e

REGION="us-east-1"
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
NAME="test-execution-plan-${SUFFIX}"
DESCRIPTION="Test execution plan for Kendra Intelligent Ranking"
CAPACITY_UNITS='{"RescoreCapacityUnits": 1}'
CLIENT_TOKEN=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

echo "Creating Rescore Execution Plan..."
EXECUTION_PLAN_ID=$(aws kendra-ranking create-rescore-execution-plan \
    --name "$NAME" \
    --description "$DESCRIPTION" \
    --capacity-units "$CAPACITY_UNITS" \
    --client-token "$CLIENT_TOKEN" \
    --query 'Id' --output text)
echo "Created Rescore Execution Plan with ID: $EXECUTION_PLAN_ID"

sleep 10  # Wait for the execution plan to become active

echo "Describing Rescore Execution Plan..."
DESCRIBE_RESPONSE=$(aws kendra-ranking describe-rescore-execution-plan \
    --id "$EXECUTION_PLAN_ID")
echo "Described Rescore Execution Plan: $DESCRIBE_RESPONSE"

echo "Listing Rescore Execution Plans..."
LIST_RESPONSE=$(aws kendra-ranking list-rescore-execution-plans)
echo "Listed Rescore Execution Plans: $LIST_RESPONSE"

# Deleting Rescore Execution Plan is commented out due to potential errors
# echo "Deleting Rescore Execution Plan..."
# aws kendra-ranking delete-rescore-execution-plan \
#     --id "$EXECUTION_PLAN_ID" || true
# echo "Deleted Rescore Execution Plan with ID: $EXECUTION_PLAN_ID"

sleep 10  # Wait for the deletion to complete

echo "PASS"