#!/bin/bash

# Amazon Cognito User Pools Getting Started Script
# This script creates and configures an Amazon Cognito user pool with an app client

# Set up logging
LOG_FILE="cognito-user-pool-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Amazon Cognito User Pool setup script at $(date)"
echo "All commands and outputs will be logged to $LOG_FILE"

# Function to check for errors in command output
check_error() {
  local output=$1
  local cmd=$2
  
  if echo "$output" | grep -i "error" > /dev/null; then
    echo "ERROR: Command failed: $cmd"
    echo "Output: $output"
    cleanup_on_error
    exit 1
  fi
}

# Function to clean up resources on error
cleanup_on_error() {
  echo "Error encountered. Attempting to clean up resources..."
  
  if [ -n "$DOMAIN_NAME" ] && [ -n "$USER_POOL_ID" ]; then
    echo "Deleting user pool domain: $DOMAIN_NAME"
    aws cognito-idp delete-user-pool-domain --user-pool-id "$USER_POOL_ID" --domain "$DOMAIN_NAME"
  fi
  
  if [ -n "$USER_POOL_ID" ]; then
    echo "Deleting user pool: $USER_POOL_ID"
    aws cognito-idp delete-user-pool --user-pool-id "$USER_POOL_ID"
  fi
}

# Get the current AWS region
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
  AWS_REGION="us-east-1" # Default region if not configured
fi
echo "Using AWS Region: $AWS_REGION"

# Generate random identifier for resource names
RANDOM_ID=$(openssl rand -hex 6)
USER_POOL_NAME="MyUserPool-${RANDOM_ID}"
APP_CLIENT_NAME="MyAppClient-${RANDOM_ID}"
DOMAIN_NAME="my-auth-domain-${RANDOM_ID}"

echo "Using random identifier: $RANDOM_ID"
echo "User pool name: $USER_POOL_NAME"
echo "App client name: $APP_CLIENT_NAME"
echo "Domain name: $DOMAIN_NAME"

# Step 1: Create a User Pool
echo "Creating user pool..."
USER_POOL_OUTPUT=$(aws cognito-idp create-user-pool \
  --pool-name "$USER_POOL_NAME" \
  --auto-verified-attributes email \
  --username-attributes email \
  --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":false}}' \
  --schema '[{"Name":"email","Required":true,"Mutable":true}]' \
  --mfa-configuration OFF)

check_error "$USER_POOL_OUTPUT" "create-user-pool"

# Extract the User Pool ID
USER_POOL_ID=$(echo "$USER_POOL_OUTPUT" | grep -o '"Id": "[^"]*' | cut -d'"' -f4)
if [ -z "$USER_POOL_ID" ]; then
  echo "Failed to extract User Pool ID"
  exit 1
fi

echo "User Pool created with ID: $USER_POOL_ID"

# Wait for user pool to be ready
echo "Waiting for user pool to be ready..."
sleep 5

# Step 2: Create an App Client
echo "Creating app client..."
APP_CLIENT_OUTPUT=$(aws cognito-idp create-user-pool-client \
  --user-pool-id "$USER_POOL_ID" \
  --client-name "$APP_CLIENT_NAME" \
  --no-generate-secret \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --callback-urls '["https://localhost:3000/callback"]')

check_error "$APP_CLIENT_OUTPUT" "create-user-pool-client"

# Extract the Client ID
CLIENT_ID=$(echo "$APP_CLIENT_OUTPUT" | grep -o '"ClientId": "[^"]*' | cut -d'"' -f4)
if [ -z "$CLIENT_ID" ]; then
  echo "Failed to extract Client ID"
  cleanup_on_error
  exit 1
fi

echo "App Client created with ID: $CLIENT_ID"

# Step 3: Set Up a Domain for Your User Pool
echo "Setting up user pool domain..."
DOMAIN_OUTPUT=$(aws cognito-idp create-user-pool-domain \
  --user-pool-id "$USER_POOL_ID" \
  --domain "$DOMAIN_NAME")

check_error "$DOMAIN_OUTPUT" "create-user-pool-domain"
echo "Domain created: $DOMAIN_NAME.auth.$AWS_REGION.amazoncognito.com"

# Step 4: View User Pool Details
echo "Retrieving user pool details..."
USER_POOL_DETAILS=$(aws cognito-idp describe-user-pool \
  --user-pool-id "$USER_POOL_ID")

check_error "$USER_POOL_DETAILS" "describe-user-pool"
echo "User Pool details retrieved successfully"

# Step 5: View App Client Details
echo "Retrieving app client details..."
APP_CLIENT_DETAILS=$(aws cognito-idp describe-user-pool-client \
  --user-pool-id "$USER_POOL_ID" \
  --client-id "$CLIENT_ID")

check_error "$APP_CLIENT_DETAILS" "describe-user-pool-client"
echo "App Client details retrieved successfully"

# Step 6: Create a User (Admin)
echo "Creating admin user..."
ADMIN_USER_EMAIL="admin@example.com"
ADMIN_USER_OUTPUT=$(aws cognito-idp admin-create-user \
  --user-pool-id "$USER_POOL_ID" \
  --username "$ADMIN_USER_EMAIL" \
  --user-attributes Name=email,Value="$ADMIN_USER_EMAIL" Name=email_verified,Value=true \
  --temporary-password "Temp123!")

check_error "$ADMIN_USER_OUTPUT" "admin-create-user"
echo "Admin user created: $ADMIN_USER_EMAIL"

# Step 7: Self-Registration
echo "Demonstrating self-registration..."
USER_EMAIL="user@example.com"
SIGNUP_OUTPUT=$(aws cognito-idp sign-up \
  --client-id "$CLIENT_ID" \
  --username "$USER_EMAIL" \
  --password "Password123!" \
  --user-attributes Name=email,Value="$USER_EMAIL")

check_error "$SIGNUP_OUTPUT" "sign-up"
echo "User signed up: $USER_EMAIL"
echo "A confirmation code would be sent to the user's email in a real scenario"

echo ""
echo "==================================================="
echo "IMPORTANT: In a real scenario, the user would receive"
echo "a confirmation code via email. For this demo, we'll"
echo "use admin-confirm-sign-up instead."
echo "==================================================="
echo ""

# Step 8: Confirm User Registration (using admin privileges for demo)
echo "Confirming user registration (admin method)..."
CONFIRM_OUTPUT=$(aws cognito-idp admin-confirm-sign-up \
  --user-pool-id "$USER_POOL_ID" \
  --username "$USER_EMAIL")

check_error "$CONFIRM_OUTPUT" "admin-confirm-sign-up"
echo "User confirmed: $USER_EMAIL"

# Step 9: Authenticate a User
echo "Authenticating user..."
AUTH_OUTPUT=$(aws cognito-idp initiate-auth \
  --client-id "$CLIENT_ID" \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME="$USER_EMAIL",PASSWORD="Password123!")

check_error "$AUTH_OUTPUT" "initiate-auth"
echo "User authenticated successfully"

# Step 10: List Users in the User Pool
echo "Listing users in the user pool..."
USERS_OUTPUT=$(aws cognito-idp list-users \
  --user-pool-id "$USER_POOL_ID")

check_error "$USERS_OUTPUT" "list-users"
echo "Users listed successfully"

# Display summary of created resources
echo ""
echo "==================================================="
echo "RESOURCE SUMMARY"
echo "==================================================="
echo "User Pool ID: $USER_POOL_ID"
echo "User Pool Name: $USER_POOL_NAME"
echo "App Client ID: $CLIENT_ID"
echo "App Client Name: $APP_CLIENT_NAME"
echo "Domain: $DOMAIN_NAME.auth.$AWS_REGION.amazoncognito.com"
echo "Admin User: $ADMIN_USER_EMAIL"
echo "Regular User: $USER_EMAIL"
echo "==================================================="
echo ""

# Prompt for cleanup
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
  echo "Starting cleanup process..."
  
  # Step 11: Clean Up Resources
  echo "Deleting user pool domain..."
  DELETE_DOMAIN_OUTPUT=$(aws cognito-idp delete-user-pool-domain \
    --user-pool-id "$USER_POOL_ID" \
    --domain "$DOMAIN_NAME")
  
  check_error "$DELETE_DOMAIN_OUTPUT" "delete-user-pool-domain"
  echo "Domain deleted successfully"
  
  # Wait for domain deletion to complete
  echo "Waiting for domain deletion to complete..."
  sleep 5
  
  echo "Deleting user pool (this will also delete the app client)..."
  DELETE_POOL_OUTPUT=$(aws cognito-idp delete-user-pool \
    --user-pool-id "$USER_POOL_ID")
  
  check_error "$DELETE_POOL_OUTPUT" "delete-user-pool"
  echo "User pool deleted successfully"
  
  echo "All resources have been cleaned up"
else
  echo "Resources will not be deleted. You can manually delete them later."
  echo "To delete the resources manually, use the following commands:"
  echo "aws cognito-idp delete-user-pool-domain --user-pool-id $USER_POOL_ID --domain $DOMAIN_NAME"
  echo "aws cognito-idp delete-user-pool --user-pool-id $USER_POOL_ID"
fi

echo "Script completed at $(date)"
