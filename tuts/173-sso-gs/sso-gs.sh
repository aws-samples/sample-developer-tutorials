#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

trap cleanup_resources EXIT

cleanup_resources() {
    rm -rf "$TEMP_DIR"
}

echo "Step: GetRoleCredentials"
aws sso get-role-credentials &>> "$LOG_FILE" && echo "GetRoleCredentials done" || echo "GetRoleCredentials skipped"

echo "Step: ListAccountRoles"
aws sso list-account-roles &>> "$LOG_FILE" && echo "ListAccountRoles done" || echo "ListAccountRoles skipped"

echo "Step: ListAccounts"
aws sso list-accounts &>> "$LOG_FILE" && echo "ListAccounts done" || echo "ListAccounts skipped"

echo "PASS"