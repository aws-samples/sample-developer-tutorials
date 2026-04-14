#!/bin/bash
# Tutorial: Create a Cognito user pool and manage users
# Source: https://docs.aws.amazon.com/cognito/latest/developerguide/getting-started-user-pools.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/cognito-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(openssl rand -hex 4)
POOL_NAME="tut-pool-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    [ -n "$POOL_ID" ] && aws cognito-idp delete-user-pool --user-pool-id "$POOL_ID" 2>/dev/null && \
        echo "  Deleted user pool $POOL_ID"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a user pool
echo "Step 1: Creating user pool: $POOL_NAME"
POOL_ID=$(aws cognito-idp create-user-pool --pool-name "$POOL_NAME" \
    --auto-verified-attributes email \
    --username-attributes email \
    --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":false}}' \
    --query 'UserPool.Id' --output text)
echo "  Pool ID: $POOL_ID"

# Step 2: Create an app client
echo "Step 2: Creating app client"
CLIENT_ID=$(aws cognito-idp create-user-pool-client \
    --user-pool-id "$POOL_ID" \
    --client-name "tutorial-app" \
    --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
    --query 'UserPoolClient.ClientId' --output text)
echo "  Client ID: $CLIENT_ID"

# Step 3: Create a user (admin)
echo "Step 3: Creating a user"
aws cognito-idp admin-create-user --user-pool-id "$POOL_ID" \
    --username "tutorial@example.com" \
    --user-attributes Name=email,Value=tutorial@example.com Name=email_verified,Value=true \
    --temporary-password "TutPass1!" \
    --message-action SUPPRESS \
    --query 'User.{Username:Username,Status:UserStatus,Created:UserCreateDate}' --output table

# Step 4: Set permanent password
echo "Step 4: Setting permanent password"
aws cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" \
    --username "tutorial@example.com" \
    --password "Tutorial1Pass!" --permanent > /dev/null
echo "  Password set"

# Step 5: List users
echo "Step 5: Listing users"
aws cognito-idp list-users --user-pool-id "$POOL_ID" \
    --query 'Users[].{Username:Username,Status:UserStatus,Enabled:Enabled}' --output table

# Step 6: Describe the user pool
echo "Step 6: User pool details"
aws cognito-idp describe-user-pool --user-pool-id "$POOL_ID" \
    --query 'UserPool.{Name:Name,Id:Id,Status:Status,Users:EstimatedNumberOfUsers,MFA:MfaConfiguration}' --output table

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws cognito-idp delete-user-pool --user-pool-id $POOL_ID"
fi
