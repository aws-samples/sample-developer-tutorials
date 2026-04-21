#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/transfer.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$SERVER_ID" ] && aws transfer delete-server --server-id "$SERVER_ID" 2>/dev/null && echo "  Deleted server (takes ~1 min)"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating SFTP server"
SERVER_ID=$(aws transfer create-server --protocols SFTP --endpoint-type PUBLIC --identity-provider-type SERVICE_MANAGED --query 'ServerId' --output text)
echo "  Server ID: $SERVER_ID"
echo "Step 2: Waiting for server..."
for i in $(seq 1 20); do STATUS=$(aws transfer describe-server --server-id "$SERVER_ID" --query 'Server.State' --output text); echo "  $STATUS"; [ "$STATUS" = "ONLINE" ] && break; sleep 10; done
echo "Step 3: Server details"
aws transfer describe-server --server-id "$SERVER_ID" --query 'Server.{Id:ServerId,State:State,Endpoint:EndpointDetails.AddressAllocationIds,Protocols:Protocols}' --output table
echo "Step 4: Listing servers"
aws transfer list-servers --query 'Servers[:3].{Id:ServerId,State:State,Protocols:Protocols}' --output table
echo ""; echo "Tutorial complete."
echo "Note: Transfer Family servers incur hourly charges (~\$0.30/hr). Clean up promptly."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
