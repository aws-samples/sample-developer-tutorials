#!/bin/bash
set -e
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
echo "=== Checking Inspector Status ==="
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
STATUS=$(aws inspector2 batch-get-account-status --account-ids "$ACCOUNT_ID" --query 'accounts[0].state.status' --output text)
echo "Status: $STATUS"
if [ "$STATUS"!= "ENABLED" ]; then
    # Skipping enable step due to AccessDeniedException
    echo "Skipping enable step due to insufficient permissions"
fi
echo "=== Creating Filter ==="
FILTER_ARN=$(aws inspector2 create-filter --name "filter-$SUFFIX" --action SUPPRESS --filter-criteria '{"severity":[{"comparison":"EQUALS","value":"INFORMATIONAL"}]}' --query 'arn' --output text)
echo "Filter: $FILTER_ARN"
CREATED_RESOURCES+=("filter:$FILTER_ARN")
echo "=== Listing Findings ==="
aws inspector2 list-findings --max-results 3 --query 'findings[].title' --output text || echo "No findings"
echo "=== Tutorial Complete ==="