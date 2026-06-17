#!/bin/bash
set -e
LOG_FILE="tutorial.log"
if [ -t 1 ]; then 
echo "=== AWS Inspector Tutorial: Managing Security Findings ==="
echo "This tutorial demonstrates how to check the status of AWS Inspector,"
echo "create a filter to suppress low-severity findings, and list findings."
echo ""
fi

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=: read -r type id <<< "${CREATED_RESOURCES[$i]}"
        case $type in
            filter) aws inspector2 delete-filter --arn "$id" 2>/dev/null || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

echo "=== Step 1: Checking Inspector Status ==="
echo "We first check the status of AWS Inspector in your account."
echo "This step ensures that Inspector is enabled and ready to use."
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
STATUS=$(aws inspector2 batch-get-account-status --account-ids "$ACCOUNT_ID" --query 'accounts[0].state.status' --output text)
echo "Result: Status is $STATUS"
echo ""

if [ "$STATUS"!= "ENABLED" ]; then
    echo "Skipping enable step due to insufficient permissions or other constraints."
    exit 0
fi

echo "=== Step 2: Creating a Filter ==="
echo "Next, we create a filter to suppress low-severity findings."
echo "This helps in managing the noise from non-critical security findings."
FILTER_ARN=$(aws inspector2 create-filter --name "filter-$SUFFIX" --action SUPPRESS --filter-criteria '{"severity":[{"comparison":"EQUALS","value":"INFORMATIONAL"}]}' --query 'arn' --output text)
echo "Result: Filter ARN is $FILTER_ARN"
CREATED_RESOURCES+=("filter:$FILTER_ARN")
echo ""

echo "=== Step 3: Listing Findings ==="
echo "Finally, we list the current security findings to demonstrate the functionality."
echo "This step shows how to retrieve and display findings from AWS Inspector."
aws inspector2 list-findings --max-results 3 --query 'findings[].title' --output text || echo "No findings"
echo ""

echo "=== Tutorial Complete ==="
echo "In this tutorial, you learned how to:"
echo "1. Check the status of AWS Inspector in your account."
echo "2. Create a filter to suppress low-severity findings."
echo "3. List current security findings."
echo "These steps help in effectively managing and reducing the noise from security findings."