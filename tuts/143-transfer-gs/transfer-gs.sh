#!/bin/bash
set -e

cleanup() {
  if [[ -n $SERVER_ID ]]; then
    aws transfer delete-server --server-id $SERVER_ID
  fi
}

trap cleanup EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
SERVER_ID=$(aws transfer create-server --endpoint-type PUBLIC --protocols SFTP --identity-provider-type SERVICE_MANAGED --query 'ServerId' --output text)

while true; do
  STATUS=$(aws transfer describe-server --server-id $SERVER_ID --query 'Server.Status' --output text)
  if [[ $STATUS == "ONLINE" ]]; then
    break
  fi
  sleep 10
done

aws transfer describe-server --server-id $SERVER_ID

echo "PASS"
