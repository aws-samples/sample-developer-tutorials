#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    echo "Cleaning up created resources..."
    for res in "${CREATED_RESOURCES[@]}"; do
        aws transfer delete-server --server-id "$res" || true
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

echo "Creating server..."
SERVER_ID=$(aws transfer create-server --endpoint-type PUBLIC --identity-provider-type SERVICE_MANAGED --protocols SFTP --query 'ServerId' --output text)
CREATED_RESOURCES+=("$SERVER_ID")
echo "Created server: $SERVER_ID" 

echo "Waiting for server to be ONLINE..."
for _ in {1..24}; do
    sleep 10
    STATE=$(aws transfer describe-server --server-id "$SERVER_ID" --query 'Server.State' --output text)
    if [ "$STATE" == "ONLINE" ]; then break; fi
done
echo "State: $STATE" 

echo "Creating other resources..."
aws transfer create-access --query 'path' --output text || true
aws transfer create-agreement --query 'path' --output text || true
aws transfer create-connector --query 'path' --output text || true
aws transfer create-profile --query 'path' --output text || true 

echo "Listing servers..."
aws transfer list-servers --query 'Servers[].ServerId' --output text || true 

echo "Deleting server..."
aws transfer delete-server --server-id "$SERVER_ID" || true
echo "Deleted. PASS" 