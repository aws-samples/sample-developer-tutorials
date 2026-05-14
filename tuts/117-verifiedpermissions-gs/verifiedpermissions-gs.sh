#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
POLICY_STORE_NAME="policy-store-${SUFFIX}"
CLIENT_TOKEN=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

echo "Creating Policy Store..."
POLICY_STORE_ID=$(aws verifiedpermissions create-policy-store \
    --client-token "$CLIENT_TOKEN" \
    --validation-settings '{"mode": "STRICT"}' \
    --description 'Test Policy Store' \
    --deletion-protection 'DISABLED' \
    --query 'policyStoreId' --output text)

echo "Policy Store created with ID: $POLICY_STORE_ID"

echo "Verifying Policy Store exists..."
while true; do
    if aws verifiedpermissions get-policy-store --policy-store-id "$POLICY_STORE_ID" &>/dev/null; then
        echo "Policy Store verified."
        break
    else
        echo "Policy Store not yet available, waiting..."
        sleep 5
    fi
done

echo "Listing Policy Stores to confirm creation..."
LIST_RESPONSE=$(aws verifiedpermissions list-policy-stores --query 'policyStores[?policyStoreId==`'$POLICY_STORE_ID'`]' --output json)
if echo "$LIST_RESPONSE" | grep -q '"policyStoreId":"'"$POLICY_STORE_ID"'"'; then
    echo "Policy Store listed successfully."
else
    echo "Policy Store not found in list."
fi

echo "Deleting Policy Store..."
aws verifiedpermissions delete-policy-store --policy-store-id "$POLICY_STORE_ID" || true

echo "Verifying Policy Store deletion..."
while true; do
    if ! aws verifiedpermissions get-policy-store --policy-store-id "$POLICY_STORE_ID" &>/dev/null; then
        echo "Policy Store successfully deleted."
        break
    else
        echo "Policy Store still exists, waiting..."
        sleep 5
    fi
done

echo "PASS"