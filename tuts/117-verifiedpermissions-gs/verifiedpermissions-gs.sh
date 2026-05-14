#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
declare -a CREATED_RESOURCES=()
cleanup_resources() {
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=: read -r type id <<< "${CREATED_RESOURCES[$i]}"
        case $type in
            store) aws verifiedpermissions delete-policy-store --policy-store-id "$id" 2>/dev/null || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT
echo "=== Creating Policy Store ==="
STORE_ID=$(aws verifiedpermissions create-policy-store --validation-settings '{"mode":"OFF"}' --query 'policyStoreId' --output text)
echo "Store: $STORE_ID"
CREATED_RESOURCES+=("store:$STORE_ID")
echo "=== Getting Policy Store ==="
aws verifiedpermissions get-policy-store --policy-store-id "$STORE_ID" --query 'createdDate' --output text
echo "=== Listing Policy Stores ==="
aws verifiedpermissions list-policy-stores --query 'policyStores[].policyStoreId' --output text
echo "=== Tutorial Complete ==="
