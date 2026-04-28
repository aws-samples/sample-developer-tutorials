#!/bin/bash

# Script to move hardcoded secrets to AWS Secrets Manager
# This script demonstrates how to create IAM roles, store a secret in AWS Secrets Manager,
# and set up appropriate permissions

set -euo pipefail

# Set up logging
LOG_FILE="secrets_manager_tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting AWS Secrets Manager tutorial script at $(date)"
echo "======================================================"

# Function to check for errors in command output
check_error() {
    local output=$1
    local cmd=$2
    
    if echo "$output" | grep -qi "error\|invalid\|failed"; then
        echo "ERROR: Command failed: $cmd"
        echo "$output"
        cleanup_resources
        exit 1
    fi
}

# Function to generate a random identifier
generate_random_id() {
    openssl rand -hex 4
}

# Function to validate AWS CLI is available
validate_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "ERROR: AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "ERROR: AWS CLI is not configured or credentials are invalid"
        exit 1
    fi
}

# Function to validate JSON
validate_json() {
    local json=$1
    local json_name=$2
    
    if ! echo "$json" | jq empty 2>/dev/null; then
        echo "ERROR: Invalid JSON in $json_name"
        exit 1
    fi
}

# Function to clean up resources
cleanup_resources() {
    echo ""
    echo "==========================================="
    echo "RESOURCES CREATED"
    echo "==========================================="
    
    if [ -n "${SECRET_NAME:-}" ]; then
        echo "Secret: $SECRET_NAME"
    fi
    
    if [ -n "${RUNTIME_ROLE_NAME:-}" ]; then
        echo "IAM Role: $RUNTIME_ROLE_NAME"
    fi
    
    if [ -n "${ADMIN_ROLE_NAME:-}" ]; then
        echo "IAM Role: $ADMIN_ROLE_NAME"
    fi
    
    echo ""
    echo "==========================================="
    echo "CLEANUP CONFIRMATION"
    echo "==========================================="
    echo "Do you want to clean up all created resources? (y/n): "
    read -r CLEANUP_CHOICE
    
    if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
        echo "Cleaning up resources..."
        
        # Delete secret if it exists
        if [ -n "${SECRET_NAME:-}" ]; then
            echo "Deleting secret: $SECRET_NAME"
            aws secretsmanager delete-secret --secret-id "$SECRET_NAME" --force-delete-without-recovery 2>/dev/null || true
        fi
        
        # Detach policies and delete runtime role if it exists
        if [ -n "${RUNTIME_ROLE_NAME:-}" ]; then
            echo "Detaching policies from runtime role: $RUNTIME_ROLE_NAME"
            aws iam list-role-policies --role-name "$RUNTIME_ROLE_NAME" --query 'PolicyNames[]' --output text 2>/dev/null | while read -r policy; do
                [ -z "$policy" ] && continue
                aws iam delete-role-policy --role-name "$RUNTIME_ROLE_NAME" --policy-name "$policy" 2>/dev/null || true
            done
            
            echo "Deleting IAM role: $RUNTIME_ROLE_NAME"
            aws iam delete-role --role-name "$RUNTIME_ROLE_NAME" 2>/dev/null || true
        fi
        
        # Detach policies and delete admin role if it exists
        if [ -n "${ADMIN_ROLE_NAME:-}" ]; then
            echo "Detaching policy from role: $ADMIN_ROLE_NAME"
            aws iam detach-role-policy --role-name "$ADMIN_ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/SecretsManagerReadWrite" 2>/dev/null || true
            
            echo "Deleting IAM role: $ADMIN_ROLE_NAME"
            aws iam delete-role --role-name "$ADMIN_ROLE_NAME" 2>/dev/null || true
        fi
        
        echo "Cleanup completed."
    else
        echo "Resources will not be deleted."
    fi
}

# Trap to ensure cleanup on script exit
trap 'echo "Script interrupted. Running cleanup..."; cleanup_resources' INT TERM EXIT

# Validate prerequisites
validate_aws_cli

# Generate random identifiers for resources
ADMIN_ROLE_NAME="SecretsManagerAdmin-$(generate_random_id)"
RUNTIME_ROLE_NAME="RoleToRetrieveSecretAtRuntime-$(generate_random_id)"
SECRET_NAME="MyAPIKey-$(generate_random_id)"

# Cache AWS account ID at start
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text 2>&1)
check_error "$ACCOUNT_ID" "get-caller-identity"
echo "Account ID: $ACCOUNT_ID"

echo "Using the following resource names:"
echo "Admin Role: $ADMIN_ROLE_NAME"
echo "Runtime Role: $RUNTIME_ROLE_NAME"
echo "Secret Name: $SECRET_NAME"
echo ""

# Prepare JSON documents as variables
ASSUME_ROLE_POLICY='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}'

RUNTIME_POLICY='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:aws:secretsmanager:*:*:secret:MyAPIKey-*"
        }
    ]
}'

# Validate JSON before using
validate_json "$ASSUME_ROLE_POLICY" "ASSUME_ROLE_POLICY"
validate_json "$RUNTIME_POLICY" "RUNTIME_POLICY"

# Step 1: Create IAM roles
echo "Creating IAM roles..."

# Create the SecretsManagerAdmin role
echo "Creating admin role: $ADMIN_ROLE_NAME"
ADMIN_ROLE_OUTPUT=$(aws iam create-role \
    --role-name "$ADMIN_ROLE_NAME" \
    --assume-role-policy-document "$ASSUME_ROLE_POLICY" 2>&1)

check_error "$ADMIN_ROLE_OUTPUT" "create-role for admin"

aws iam tag-role --role-name "$ADMIN_ROLE_NAME" --tags Key=project,Value=doc-smith Key=tutorial,Value=aws-secrets-manager-gs 2>/dev/null || true

# Attach the SecretsManagerReadWrite policy to the admin role
echo "Attaching SecretsManagerReadWrite policy to admin role"
ATTACH_POLICY_OUTPUT=$(aws iam attach-role-policy \
    --role-name "$ADMIN_ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/SecretsManagerReadWrite" 2>&1)

check_error "$ATTACH_POLICY_OUTPUT" "attach-role-policy for admin"

# Create the RoleToRetrieveSecretAtRuntime role
echo "Creating runtime role: $RUNTIME_ROLE_NAME"
RUNTIME_ROLE_OUTPUT=$(aws iam create-role \
    --role-name "$RUNTIME_ROLE_NAME" \
    --assume-role-policy-document "$ASSUME_ROLE_POLICY" 2>&1)

check_error "$RUNTIME_ROLE_OUTPUT" "create-role for runtime"

aws iam tag-role --role-name "$RUNTIME_ROLE_NAME" --tags Key=project,Value=doc-smith Key=tutorial,Value=aws-secrets-manager-gs 2>/dev/null || true

# Create inline policy for runtime role with specific actions
echo "Adding inline policy to runtime role for GetSecretValue only..."
PUT_POLICY_OUTPUT=$(aws iam put-role-policy \
    --role-name "$RUNTIME_ROLE_NAME" \
    --policy-name "SecretsManagerGetSecretValue" \
    --policy-document "$RUNTIME_POLICY" 2>&1)

check_error "$PUT_POLICY_OUTPUT" "put-role-policy for runtime"

# Wait for roles to be fully created
echo "Waiting for IAM roles to be fully created..."
sleep 10

# Step 2: Create a secret in AWS Secrets Manager
echo "Creating secret in AWS Secrets Manager..."

CREATE_SECRET_OUTPUT=$(aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "API key for my application" \
    --secret-string '{"ClientID":"my_client_id","ClientSecret":"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"}' \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=aws-secrets-manager-gs \
    --kms-key-id alias/aws/secretsmanager 2>&1)

check_error "$CREATE_SECRET_OUTPUT" "create-secret"

# Get the secret ARN
SECRET_ARN=$(echo "$CREATE_SECRET_OUTPUT" | jq -r '.ARN' 2>/dev/null)

if [ -z "$SECRET_ARN" ] || [ "$SECRET_ARN" = "null" ]; then
    echo "ERROR: Could not extract secret ARN from create-secret output"
    cleanup_resources
    exit 1
fi

# Add resource policy to the secret with specific resource
echo "Adding resource policy to secret..."
RESOURCE_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${ACCOUNT_ID}:role/${RUNTIME_ROLE_NAME}"
            },
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "${SECRET_ARN}"
        }
    ]
}
EOF
)

validate_json "$RESOURCE_POLICY" "RESOURCE_POLICY"

RESOURCE_POLICY_OUTPUT=$(aws secretsmanager put-resource-policy \
    --secret-id "$SECRET_NAME" \
    --resource-policy "$RESOURCE_POLICY" \
    --block-public-policy 2>&1)

check_error "$RESOURCE_POLICY_OUTPUT" "put-resource-policy"

# Step 3: Demonstrate retrieving the secret
echo "Retrieving the secret value (for demonstration purposes)..."
GET_SECRET_OUTPUT=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" 2>&1)

check_error "$GET_SECRET_OUTPUT" "get-secret-value"
echo "Secret retrieved successfully."

# Step 4: Update the secret with new values
echo "Updating the secret with new values..."
UPDATE_SECRET_OUTPUT=$(aws secretsmanager update-secret \
    --secret-id "$SECRET_NAME" \
    --secret-string '{"ClientID":"my_new_client_id","ClientSecret":"bPxRfiCYEXAMPLEKEY/wJalrXUtnFEMI/K7MDENG"}' 2>&1)

check_error "$UPDATE_SECRET_OUTPUT" "update-secret"

# Step 5: Verify the updated secret
echo "Verifying the updated secret..."
VERIFY_SECRET_OUTPUT=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" 2>&1)

check_error "$VERIFY_SECRET_OUTPUT" "get-secret-value for verification"
echo "Updated secret retrieved successfully."

echo ""
echo "======================================================"
echo "Tutorial completed successfully!"
echo ""
echo "Summary of what we did:"
echo "1. Created IAM roles for managing and retrieving secrets"
echo "2. Created a secret in AWS Secrets Manager with encryption"
echo "3. Added a resource policy to control access to the secret"
echo "4. Retrieved the secret value (simulating application access)"
echo "5. Updated the secret with new values"
echo ""
echo "Security improvements implemented:"
echo "- Used openssl rand for better randomization"
echo "- Enabled KMS encryption for secrets at rest"
echo "- Applied principle of least privilege to runtime role"
echo "- Scoped resource policy to specific secret ARN"
echo "- Added inline policy for runtime role with specific actions"
echo "- Validated JSON documents before API calls"
echo "- Added AWS CLI availability and configuration checks"
echo ""
echo "Reliability improvements in this iteration:"
echo "- Added validate_aws_cli function to check prerequisites"
echo "- Added validate_json function to ensure JSON validity"
echo "- Captured all API command outputs for error checking"
echo "- Used jq for safe JSON parsing instead of grep"
echo "- Added validation for extracted values (SECRET_ARN)"
echo "- Improved error handling for critical operations"
echo ""
echo "Performance improvements in previous iterations:"
echo "- Cached AWS account ID to eliminate duplicate API calls"
echo "- Reused assume-role policy document to reduce parsing"
echo "- Consolidated JSON document generation into variables"
echo ""
echo "Next steps you might want to consider:"
echo "- Implement secret caching in your application"
echo "- Set up automatic rotation for your secrets"
echo "- Use AWS CodeGuru Reviewer to find hardcoded secrets in your code"
echo "- For multi-region applications, replicate your secrets across regions"
echo "- Enable CloudTrail logging for secret access audit"
echo ""

echo "Script completed at $(date)"
exit 0