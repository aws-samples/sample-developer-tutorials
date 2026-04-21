#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/ttl.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); TABLE="tut-ttl-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws dynamodb delete-table --table-name "$TABLE" > /dev/null 2>&1 && echo "  Deleted table"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating table"
aws dynamodb create-table --table-name "$TABLE" --key-schema AttributeName=pk,KeyType=HASH --attribute-definitions AttributeName=pk,AttributeType=S --billing-mode PAY_PER_REQUEST > /dev/null
aws dynamodb wait table-exists --table-name "$TABLE"
echo "Step 2: Enabling TTL"
aws dynamodb update-time-to-live --table-name "$TABLE" --time-to-live-specification Enabled=true,AttributeName=expires_at > /dev/null
echo "  TTL enabled on 'expires_at' attribute"
echo "Step 3: Writing items with TTL"
PAST=$(($(date +%s) - 3600))
FUTURE=$(($(date +%s) + 86400))
aws dynamodb put-item --table-name "$TABLE" --item "{\"pk\":{\"S\":\"expired-item\"},\"data\":{\"S\":\"This should expire\"},\"expires_at\":{\"N\":\"$PAST\"}}" 2>/dev/null
aws dynamodb put-item --table-name "$TABLE" --item "{\"pk\":{\"S\":\"active-item\"},\"data\":{\"S\":\"This stays\"},\"expires_at\":{\"N\":\"$FUTURE\"}}" 2>/dev/null
echo "  Wrote 2 items (1 expired, 1 active)"
echo "Step 4: Describing TTL"
aws dynamodb describe-time-to-live --table-name "$TABLE" --query 'TimeToLiveDescription.{Status:TimeToLiveStatus,Attribute:AttributeName}' --output table
echo "Step 5: Scanning items"
aws dynamodb scan --table-name "$TABLE" --query 'Items[].{pk:pk.S,data:data.S,expires:expires_at.N}' --output table
echo "  Note: DynamoDB deletes expired items within 48 hours, not immediately"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
