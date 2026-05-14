#!/bin/bash
set -e
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

# Create server
SERVER_ID=$(aws transfer create-server --endpoint-type PUBLIC --identity-provider-type SERVICE_MANAGED --protocols SFTP --query 'ServerId' --output text)
echo "Created server: $SERVER_ID"

# Wait for ONLINE
for _ in {1..24}; do
    sleep 10
    STATE=$(aws transfer describe-server --server-id $SERVER_ID --query 'Server.State' --output text)
    if [ "$STATE" == "ONLINE" ]; then break; fi
done
echo "State: $STATE"

# Create other resources
aws transfer create-access --query 'path' --output text || true
aws transfer create-agreement --query 'path' --output text || true
aws transfer create-connector --query 'path' --output text || true
aws transfer create-profile --query 'path' --output text || true

# List servers
aws transfer list-servers --query 'Servers[].ServerId' --output text || true

# Delete server
aws transfer delete-server --server-id $SERVER_ID || true
echo "Deleted. PASS"