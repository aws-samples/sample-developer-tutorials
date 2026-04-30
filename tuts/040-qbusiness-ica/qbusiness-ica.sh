#!/bin/bash

# Script to create an Amazon Q Business application with IAM Identity Center integration
# Based on: https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/create-application.html
# Version 3-working: Uses existing users since AWS CLI version doesn't support user creation

# Set AWS region explicitly to avoid cross-region issues
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"  # Uses configured region or defaults to us-east-1
export AWS_DEFAULT_REGION="$AWS_REGION"

# Initialize log file
LOG_FILE="qbusiness_app_creation.log"
echo "Starting Amazon Q Business application creation script at $(date)" > "$LOG_FILE"
echo "Using AWS Region: $AWS_REGION" >> "$LOG_FILE"

# Track created resources for cleanup
CREATED_RESOURCES=()

# Function to log commands and their outputs
log_cmd() {
    echo "$(date): COMMAND: $1" >> "$LOG_FILE"
    eval "$1" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# Function to check for errors
check_error() {
    if [ $1 -ne 0 ]; then
        echo "ERROR: Command failed with exit code $1" | tee -a "$LOG_FILE"
        echo "See $LOG_FILE for details"
        cleanup_on_error
        exit 1
    fi
}

# Function to wait for IAM role to propagate
wait_for_role() {
    local role_name="$1"
    local max_attempts=12
    local wait_time=10
    local attempt=1
    
    echo "Waiting for IAM role $role_name to propagate..." | tee -a "$LOG_FILE"
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts..." | tee -a "$LOG_FILE"
        
        # Try to get the role to verify it exists and is accessible
        if aws iam get-role --role-name "$role_name" --region "$AWS_REGION" --query 'Role.Arn' --output text >/dev/null 2>&1; then
            echo "Role $role_name has propagated successfully after $((attempt * wait_time)) seconds" | tee -a "$LOG_FILE"
            return 0
        fi
        
        echo "Waiting $wait_time seconds for role propagation..." | tee -a "$LOG_FILE"
        sleep $wait_time
        ((attempt++))
    done
    
    echo "ERROR: Role $role_name did not propagate after $((max_attempts * wait_time)) seconds" | tee -a "$LOG_FILE"
    return 1
}

# Function to cleanup resources on error
cleanup_on_error() {
    echo "" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    echo "ERROR ENCOUNTERED - CLEANING UP RESOURCES" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    
    cleanup_resources
}

# Function to display created resources and confirm cleanup
confirm_cleanup() {
    echo "" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    echo "RESOURCES CREATED" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    
    for resource in "${CREATED_RESOURCES[@]}"; do
        echo "$resource" | tee -a "$LOG_FILE"
    done
    
    echo "" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    echo "CLEANUP CONFIRMATION" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    echo "Do you want to clean up all created resources? (y/n): " | tee -a "$LOG_FILE"
    read -r CLEANUP_CHOICE
    
    if [[ "${CLEANUP_CHOICE,,}" == "y" ]]; then
        cleanup_resources
    else
        echo "Resources will not be cleaned up. You can manually delete them later." | tee -a "$LOG_FILE"
    fi
}

# Function to cleanup all resources
cleanup_resources() {
    echo "" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    echo "CLEANING UP RESOURCES" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    
    # Delete user assignment first
    if [ -n "$USER_ASSIGNMENT_ID" ] && [ -n "$APP_ARN" ] && [ -n "$USER_ID" ]; then
        echo "Deleting user assignment" | tee -a "$LOG_FILE"
        log_cmd "aws sso-admin delete-application-assignment --region $AWS_REGION --application-arn \"$APP_ARN\" --principal-id \"$USER_ID\" --principal-type USER"
    fi
    
    # Delete the application
    if [ -n "$APP_ID" ]; then
        echo "Deleting application: $APP_ID" | tee -a "$LOG_FILE"
        log_cmd "aws qbusiness delete-application --region $AWS_REGION --application-id \"$APP_ID\""
    fi
    
    # Clean up IAM roles and policies
    if [ -n "$ROLE_NAME" ]; then
        if [ -n "$POLICY_ARN" ]; then
            echo "Detaching policy from role" | tee -a "$LOG_FILE"
            log_cmd "aws iam detach-role-policy --role-name \"$ROLE_NAME\" --policy-arn \"$POLICY_ARN\""
        fi
        
        echo "Deleting role: $ROLE_NAME" | tee -a "$LOG_FILE"
        log_cmd "aws iam delete-role --role-name \"$ROLE_NAME\""
    fi
    
    if [ -n "$POLICY_ARN" ]; then
        echo "Deleting policy: $POLICY_ARN" | tee -a "$LOG_FILE"
        log_cmd "aws iam delete-policy --policy-arn \"$POLICY_ARN\""
    fi
    
    # Clean up temporary files
    rm -f qbusiness-trust-policy.json qbusiness-permissions-policy.json
    
    echo "Cleanup completed" | tee -a "$LOG_FILE"
}

# Generate a random identifier for resource names
RANDOM_ID=$(openssl rand -hex 4)
APP_NAME="MyQBusinessApp-${RANDOM_ID}"

echo "===========================================================" | tee -a "$LOG_FILE"
echo "STEP 1: Check for IAM Identity Center Instance" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

# Get the IAM Identity Center instance ARN
echo "Checking for IAM Identity Center instance..." | tee -a "$LOG_FILE"
INSTANCE_RESULT=$(log_cmd "aws sso-admin list-instances --region $AWS_REGION --query 'Instances[0].InstanceArn' --output text")
check_error $?

if [[ "$INSTANCE_RESULT" == "None" || -z "$INSTANCE_RESULT" ]]; then
    echo "No IAM Identity Center instance found. This script requires an existing IAM Identity Center instance." | tee -a "$LOG_FILE"
    echo "Please set up IAM Identity Center first and then run this script again." | tee -a "$LOG_FILE"
    exit 1
else
    IDENTITY_CENTER_ARN="$INSTANCE_RESULT"
    echo "Found existing IAM Identity Center instance: $IDENTITY_CENTER_ARN" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "STEP 2: Create Service Role for Amazon Q Business" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

# Create a trust policy file
cat > qbusiness-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AmazonQApplicationPermission",
      "Effect": "Allow",
      "Principal": {
        "Service": "qbusiness.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "$AWS_ACCOUNT_ID"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:qbusiness:$AWS_REGION:$AWS_ACCOUNT_ID:application/*"
        }
      }
    }
  ]
}
EOF

# Create a permissions policy file with specific resource constraints
cat > qbusiness-permissions-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AmazonQApplicationPutMetricDataPermission",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "cloudwatch:namespace": "AWS/QBusiness"
        }
      }
    },
    {
      "Sid": "AmazonQApplicationDescribeLogGroupsPermission",
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AmazonQApplicationCreateLogGroupPermission",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup"
      ],
      "Resource": [
        "arn:aws:logs:$AWS_REGION:$AWS_ACCOUNT_ID:log-group:/aws/qbusiness/*"
      ]
    },
    {
      "Sid": "AmazonQApplicationLogStreamPermission",
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogStreams",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:$AWS_REGION:$AWS_ACCOUNT_ID:log-group:/aws/qbusiness/*:log-stream:*"
      ]
    }
  ]
}
EOF

# Create the IAM role
ROLE_NAME="QBusinessServiceRole-${RANDOM_ID}"
echo "Creating IAM role: $ROLE_NAME" | tee -a "$LOG_FILE"
ROLE_RESULT=$(log_cmd "aws iam create-role --role-name \"$ROLE_NAME\" --assume-role-policy-document file://qbusiness-trust-policy.json --query 'Role.Arn' --output text")
check_error $?
ROLE_ARN="$ROLE_RESULT"
CREATED_RESOURCES+=("IAM Role: $ROLE_ARN")

# Create and attach the policy to the role
POLICY_NAME="QBusinessPolicy-${RANDOM_ID}"
echo "Creating IAM policy: $POLICY_NAME" | tee -a "$LOG_FILE"
POLICY_RESULT=$(log_cmd "aws iam create-policy --policy-name \"$POLICY_NAME\" --policy-document file://qbusiness-permissions-policy.json --query 'Policy.Arn' --output text")
check_error $?
POLICY_ARN="$POLICY_RESULT"
CREATED_RESOURCES+=("IAM Policy: $POLICY_ARN")

echo "Attaching policy to role" | tee -a "$LOG_FILE"
log_cmd "aws iam attach-role-policy --role-name \"$ROLE_NAME\" --policy-arn \"$POLICY_ARN\""
check_error $?

# Wait for role to propagate
wait_for_role "$ROLE_NAME"
check_error $?

echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "STEP 3: Get Identity Store ID" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

# Get the Identity Store ID directly from list-instances
echo "Getting Identity Store ID from IAM Identity Center instance..." | tee -a "$LOG_FILE"
IDENTITY_STORE_ID_RESULT=$(log_cmd "aws sso-admin list-instances --region $AWS_REGION --query 'Instances[0].IdentityStoreId' --output text")
check_error $?
IDENTITY_STORE_ID="$IDENTITY_STORE_ID_RESULT"

echo "Identity Store ID: $IDENTITY_STORE_ID" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "STEP 4: Select an Existing User in IAM Identity Center" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

# List existing users and let the user choose
echo "Listing existing users in IAM Identity Center..." | tee -a "$LOG_FILE"
USERS_RESULT=$(log_cmd "aws identitystore list-users --region $AWS_REGION --identity-store-id \"$IDENTITY_STORE_ID\"")
check_error $?

# Extract user information
echo "Available users:" | tee -a "$LOG_FILE"
USER_LIST=$(echo "$USERS_RESULT" | jq -r '.Users[] | "\(.UserName) (\(.UserId))"')
echo "$USER_LIST" | tee -a "$LOG_FILE"

# Use the first available user for automation
USER_ID=$(echo "$USERS_RESULT" | jq -r '.Users[0].UserId')
USER_NAME=$(echo "$USERS_RESULT" | jq -r '.Users[0].UserName')

if [[ -z "$USER_ID" || "$USER_ID" == "null" ]]; then
    echo "No users found in IAM Identity Center. Please create a user first." | tee -a "$LOG_FILE"
    cleanup_on_error
    exit 1
fi

echo "Using user: $USER_NAME (ID: $USER_ID)" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "STEP 5: Create Amazon Q Business Application" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

echo "Creating Amazon Q Business application: $APP_NAME" | tee -a "$LOG_FILE"
APP_RESULT=$(log_cmd "aws qbusiness create-application --region $AWS_REGION \
  --display-name \"$APP_NAME\" \
  --identity-center-instance-arn \"$IDENTITY_CENTER_ARN\" \
  --role-arn \"$ROLE_ARN\" \
  --description \"Amazon Q Business application created via script\" \
  --attachments-configuration '{\"attachmentsControlMode\":\"ENABLED\"}' \
  --query 'applicationId' --output text")
check_error $?
APP_ID="$APP_RESULT"
CREATED_RESOURCES+=("Amazon Q Business Application: $APP_ID")

echo "Application created with ID: $APP_ID" | tee -a "$LOG_FILE"

# Wait for application to be created
echo "Waiting for application to be created..." | tee -a "$LOG_FILE"
sleep 30

# Get the application ARN from IAM Identity Center with improved retry logic
echo "Getting application ARN from IAM Identity Center..." | tee -a "$LOG_FILE"
MAX_RETRIES=10
RETRY_COUNT=0
APP_ARN=""

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Use 'Name' instead of 'DisplayName' to match the working tutorial
    APP_ARN_RESULT=$(log_cmd "aws sso-admin list-applications --region $AWS_REGION --instance-arn \"$IDENTITY_CENTER_ARN\" --query \"Applications[?Name=='$APP_NAME'].ApplicationArn\" --output text")
    check_error $?
    APP_ARN="$APP_ARN_RESULT"
    
    if [[ -n "$APP_ARN" && "$APP_ARN" != "None" ]]; then
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    SLEEP_TIME=$((5 * RETRY_COUNT))
    echo "Could not find application ARN. Retry $RETRY_COUNT of $MAX_RETRIES. Waiting $SLEEP_TIME seconds..." | tee -a "$LOG_FILE"
    sleep $SLEEP_TIME
done

if [[ -z "$APP_ARN" || "$APP_ARN" == "None" ]]; then
    echo "Failed to get application ARN after $MAX_RETRIES retries. Cannot continue." | tee -a "$LOG_FILE"
    cleanup_on_error
    exit 1
fi

echo "Application ARN: $APP_ARN" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "STEP 6: Assign User to Application" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

echo "Assigning user to application" | tee -a "$LOG_FILE"
USER_ASSIGNMENT_RESULT=$(log_cmd "aws sso-admin create-application-assignment --region $AWS_REGION \
  --application-arn \"$APP_ARN\" \
  --principal-id \"$USER_ID\" \
  --principal-type USER")
check_error $?
USER_ASSIGNMENT_ID="assigned"
CREATED_RESOURCES+=("User Assignment: $USER_ID to $APP_ARN")

echo "User assigned to application" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "STEP 7: Create User Subscription" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

echo "Creating user subscription" | tee -a "$LOG_FILE"
# Use 'Q_BUSINESS' instead of 'PRO' to match the working tutorial
USER_SUBSCRIPTION_RESULT=$(log_cmd "aws qbusiness create-subscription --region $AWS_REGION \
  --application-id \"$APP_ID\" \
  --principal user=\"$USER_ID\" \
  --type Q_BUSINESS \
  --query 'subscriptionId' --output text")
check_error $?
USER_SUBSCRIPTION_ID="$USER_SUBSCRIPTION_RESULT"
CREATED_RESOURCES+=("User Subscription: $USER_SUBSCRIPTION_ID")

echo "User subscription created with ID: $USER_SUBSCRIPTION_ID" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "STEP 8: Enable Creator Mode (LLM Direct Chat)" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

echo "Enabling creator mode to allow direct chat with LLM" | tee -a "$LOG_FILE"
CREATOR_MODE_RESULT=$(log_cmd "aws qbusiness update-chat-controls-configuration --region $AWS_REGION \
  --application-id \"$APP_ID\" \
  --creator-mode-configuration '{\"creatorModeControl\": \"ENABLED\"}' \
  --query 'creatorModeConfiguration.creatorModeControl' --output text")
check_error $?

echo "Creator mode enabled: $CREATOR_MODE_RESULT" | tee -a "$LOG_FILE"
CREATED_RESOURCES+=("Creator Mode Configuration: ENABLED")

echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "STEP 9: Verify Resources" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

echo "Verifying application" | tee -a "$LOG_FILE"
log_cmd "aws qbusiness get-application --region $AWS_REGION --application-id \"$APP_ID\""
check_error $?

echo "Listing user subscriptions" | tee -a "$LOG_FILE"
log_cmd "aws qbusiness list-subscriptions --region $AWS_REGION --application-id \"$APP_ID\""
check_error $?

echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "SUMMARY" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "Amazon Q Business application has been successfully created!" | tee -a "$LOG_FILE"
echo "Application ID: $APP_ID" | tee -a "$LOG_FILE"
echo "Application ARN: $APP_ARN" | tee -a "$LOG_FILE"
echo "User ID: $USER_ID" | tee -a "$LOG_FILE"
echo "User Name: $USER_NAME" | tee -a "$LOG_FILE"
echo "User Subscription ID: $USER_SUBSCRIPTION_ID" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"

# Ask user if they want to clean up resources
confirm_cleanup

echo "Script completed successfully!" | tee -a "$LOG_FILE"
