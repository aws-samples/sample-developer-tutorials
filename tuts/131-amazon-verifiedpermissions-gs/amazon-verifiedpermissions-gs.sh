#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/avp-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4)
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$STORE_ID" ] && aws verifiedpermissions delete-policy-store --policy-store-id "$STORE_ID" 2>/dev/null && echo "  Deleted policy store"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating policy store"
STORE_ID=$(aws verifiedpermissions create-policy-store --validation-settings '{"mode":"OFF"}' --query 'policyStoreId' --output text)
echo "  Store ID: $STORE_ID"
echo "Step 2: Creating a static policy"
POLICY_ID=$(aws verifiedpermissions create-policy --policy-store-id "$STORE_ID" --definition '{"static":{"statement":"permit(principal, action == Action::\"view\", resource);"}}' --query 'policyId' --output text)
echo "  Policy ID: $POLICY_ID"
echo "Step 3: Testing authorization"
aws verifiedpermissions is-authorized --policy-store-id "$STORE_ID" --principal '{"entityType":"User","entityId":"alice"}' --action '{"actionType":"Action","actionId":"view"}' --resource '{"entityType":"Document","entityId":"doc-1"}' --query '{Decision:decision}' --output table
echo "Step 4: Testing denied action"
aws verifiedpermissions is-authorized --policy-store-id "$STORE_ID" --principal '{"entityType":"User","entityId":"alice"}' --action '{"actionType":"Action","actionId":"delete"}' --resource '{"entityType":"Document","entityId":"doc-1"}' --query '{Decision:decision}' --output table
echo "Step 5: Listing policies"
aws verifiedpermissions list-policies --policy-store-id "$STORE_ID" --query 'policies[].{Id:policyId,Type:policyType}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
