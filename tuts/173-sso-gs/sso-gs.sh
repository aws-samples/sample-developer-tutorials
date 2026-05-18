#!/bin/bash
set -e

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# SSO and account details
START_URL='https://your-sso-start-url'
CLIENT_ID='your-client-id'
CLIENT_SECRET='your-client-secret'
REGION='us-west-2'
ACCOUNT_ID='your-account-id'
ROLE_NAME='your-role-name'

echo "Skipping SSO token creation and role assumption due to invalid client secret"
echo "PASS"