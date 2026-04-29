#!/bin/bash

# Script to create an Amazon Q Business application environment for anonymous access
# This script creates an Amazon Q Business application with anonymous access
# Web experience setup must be done through the AWS Management Console

set -euo pipefail

# Set up logging
LOG_FILE="qbusiness-anonymous-app-creation.log"
echo "Starting script execution at $(date)" > "$LOG_FILE"

# Set region to a supported region for Amazon Q Business
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
echo "Using AWS region: $AWS_REGION" | tee -a "$LOG_FILE"

# Function to log commands and their outputs
log_cmd() {
    local cmd="$1"
    echo "$(date): COMMAND: $cmd" >> "$LOG_FILE"
    local output
    local status=0
    output=$(eval "$cmd" 2>&1) || status=$?
    echo "$output" | tee -a "$LOG_FILE"
    return $status
}

# Function to check for errors in command output
check_error() {
    local cmd_output="$1"
    local cmd_status="$2"
    local error_msg="$3"
    
    if [ $cmd_status -ne 0 ]; then
        echo "ERROR: $error_msg" | tee -a "$LOG_FILE"
        echo "Command output: $cmd_output" | tee -a "$LOG_FILE"
        cleanup_resources
        exit 1
    fi
    
    # Only check for error keyword if it's not in the get-application response
    # The get-application response contains an "error": {} field which is normal
    if [[ "$1" != *"get-application"* ]] && echo "$cmd_output" | grep -i "error" | grep -v "error\": {}" > /dev/null; then
        echo "ERROR: $error_msg" | tee -a "$LOG_FILE"
        echo "Command output: $cmd_output" | tee -a "$LOG_FILE"
        cleanup_resources
        exit 1
    fi
}

# Function to clean up resources
cleanup_resources() {
    echo "" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    echo "CLEANUP PROCESS STARTED" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    
    # Delete application if it was created
    if [ -n "${APPLICATION_ID:-}" ]; then
        echo "Deleting application: $APPLICATION_ID" | tee -a "$LOG_FILE"
        log_cmd "aws qbusiness delete-application --application-id \"$APPLICATION_ID\" --region \"$AWS_REGION\"" || true
    fi
    
    # Delete IAM role if it was created
    if [ -n "${ROLE_NAME:-}" ]; then
        echo "Detaching policies from IAM role..." | tee -a "$LOG_FILE"
        log_cmd "aws iam detach-role-policy --role-name \"$ROLE_NAME\" --policy-arn arn:aws:iam::aws:policy/AmazonQFullAccess" || true
        echo "Deleting IAM role: $ROLE_NAME" | tee -a "$LOG_FILE"
        log_cmd "aws iam delete-role --role-name \"$ROLE_NAME\"" || true
    fi
    
    # Clean up JSON files
    if [ -f "qbusiness-trust-policy.json" ]; then
        rm -f qbusiness-trust-policy.json
    fi
    
    echo "Cleanup completed" | tee -a "$LOG_FILE"
}

# Set trap to cleanup on exit
trap cleanup_resources EXIT

# Track created resources
CREATED_RESOURCES=""
APPLICATION_ID=""
ROLE_NAME=""

# Generate a random identifier for resource names using secure method
RANDOM_ID=$(openssl rand -hex 4)
APP_NAME="AnonymousQBusinessApp-${RANDOM_ID}"

echo "===========================================================" | tee -a "$LOG_FILE"
echo "Creating Amazon Q Business Application for Anonymous Access" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

# Create IAM role for Amazon Q Business if not provided
# Note: In a production environment, you should use a pre-created role with proper permissions
echo "Creating IAM role for Amazon Q Business..." | tee -a "$LOG_FILE"

# Create trust policy document with secure file creation
TRUST_POLICY_FILE=$(mktemp)
trap "rm -f '$TRUST_POLICY_FILE'" EXIT

cat > "$TRUST_POLICY_FILE" << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "qbusiness.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

chmod 600 "$TRUST_POLICY_FILE"

# Create IAM role
ROLE_NAME="QBusinessServiceRole-${RANDOM_ID}"
ROLE_OUTPUT=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document "file://$TRUST_POLICY_FILE" --output json 2>&1)
check_error "$ROLE_OUTPUT" $? "Failed to create IAM role"

# Extract role ARN using jq for safer JSON parsing
if command -v jq &> /dev/null; then
    ROLE_ARN=$(echo "$ROLE_OUTPUT" | jq -r '.Role.Arn')
else
    ROLE_ARN=$(echo "$ROLE_OUTPUT" | grep -o '"Arn": "[^"]*' | cut -d'"' -f4)
fi

if [ -z "$ROLE_ARN" ]; then
    echo "ERROR: Failed to extract role ARN" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Created IAM role: $ROLE_ARN" | tee -a "$LOG_FILE"
CREATED_RESOURCES="IAM Role: $ROLE_NAME\n$CREATED_RESOURCES"

# Attach necessary permissions to the role
POLICY_OUTPUT=$(aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/AmazonQFullAccess" 2>&1)
check_error "$POLICY_OUTPUT" $? "Failed to attach policy to IAM role"

echo "Waiting for IAM role to propagate..." | tee -a "$LOG_FILE"
sleep 15

# Create Amazon Q Business application with anonymous access
echo "Creating Amazon Q Business application..." | tee -a "$LOG_FILE"
APP_OUTPUT=$(aws qbusiness create-application \
  --region "$AWS_REGION" \
  --display-name "$APP_NAME" \
  --identity-type ANONYMOUS \
  --role-arn "$ROLE_ARN" \
  --description "Amazon Q Business application with anonymous access" \
  --output json 2>&1)
check_error "$APP_OUTPUT" $? "Failed to create Amazon Q Business application"

# Extract application ID using jq for safer JSON parsing
if command -v jq &> /dev/null; then
    APPLICATION_ID=$(echo "$APP_OUTPUT" | jq -r '.applicationId')
else
    APPLICATION_ID=$(echo "$APP_OUTPUT" | grep -o '"applicationId": "[^"]*' | cut -d'"' -f4)
fi

if [ -z "$APPLICATION_ID" ]; then
    echo "ERROR: Failed to extract application ID" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Created Amazon Q Business application: $APPLICATION_ID" | tee -a "$LOG_FILE"
CREATED_RESOURCES="Amazon Q Business Application: $APPLICATION_ID\n$CREATED_RESOURCES"

# Wait for application to be active
echo "Waiting for application to become active..." | tee -a "$LOG_FILE"
sleep 30

# Verify application creation
VERIFY_OUTPUT=$(aws qbusiness get-application --application-id "$APPLICATION_ID" --region "$AWS_REGION" --output json 2>&1)
check_error "$VERIFY_OUTPUT" $? "Failed to verify application creation"

# Check if application status is ACTIVE using jq for safer JSON parsing
if command -v jq &> /dev/null; then
    APP_STATUS=$(echo "$VERIFY_OUTPUT" | jq -r '.status')
else
    APP_STATUS=$(echo "$VERIFY_OUTPUT" | grep -o '"status": "[^"]*' | cut -d'"' -f4)
fi

if [ "$APP_STATUS" != "ACTIVE" ]; then
    echo "ERROR: Application is not in ACTIVE state. Current status: $APP_STATUS" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Application verified successfully with status: $APP_STATUS" | tee -a "$LOG_FILE"

# Display summary of created resources
echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "SUMMARY OF CREATED RESOURCES:" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo -e "$CREATED_RESOURCES" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

# Instructions for web experience setup with direct console link
echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "WEB EXPERIENCE SETUP INSTRUCTIONS" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "To set up a web experience for your anonymous application:" | tee -a "$LOG_FILE"
echo "1. Access your application directly in the AWS Console:" | tee -a "$LOG_FILE"
echo "   https://${AWS_REGION}.console.aws.amazon.com/amazonq/business/applications/${APPLICATION_ID}" | tee -a "$LOG_FILE"
echo "2. Click on 'Web experiences' in the left navigation" | tee -a "$LOG_FILE"
echo "3. Click 'Create web experience'" | tee -a "$LOG_FILE"
echo "4. Follow the console wizard to complete the setup" | tee -a "$LOG_FILE"
echo "5. Note the web experience URL for user access" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"

echo "Script completed successfully. See $LOG_FILE for details." | tee -a "$LOG_FILE"