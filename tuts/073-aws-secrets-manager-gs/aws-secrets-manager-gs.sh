#!/bin/bash

# Script to move hardcoded secrets to AWS Secrets Manager
# This script demonstrates how to create IAM roles, store a secret in AWS Secrets Manager,
# and set up appropriate permissions

# Set up logging
LOG_FILE="secrets_manager_tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting AWS Secrets Manager tutorial script at $(date)"
echo "======================================================"

# Function to check for errors in command output
check_error() {
    local output=$1
    local cmd=$2
    
    if echo "$output" | grep -i "error" > /dev/null; then
        echo "ERROR: Command failed: $cmd"
        echo "$output"
        cleanup_resources
        exit 1
    fi
}

# Function to generate a random identifier
generate_random_id() {
    echo "sm$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)"
}

# Function to clean up resources
cleanup_resources() {
    echo ""
    echo "==========================================="
    echo "RESOURCES CREATED"
    echo "==========================================="
    
    if [ -n "$SECRET_NAME" ]; then
        echo "Secret: $SECRET_NAME"
    fi
    
    if [ -n "$RUNTIME_ROLE_NAME" ]; then
        echo "IAM Role: $RUNTIME_ROLE_NAME"
    fi
    
    if [ -n "$ADMIN_ROLE_NAME" ]; then
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
        if [ -n "$SECRET_NAME" ]; then
            echo "Deleting secret: $SECRET_NAME"
            aws secretsmanager delete-secret --secret-id "$SECRET_NAME" --force-delete-without-recovery
        fi
        
        # Detach policies and delete runtime role if it exists
        if [ -n "$RUNTIME_ROLE_NAME" ]; then
            echo "Deleting IAM role: $RUNTIME_ROLE_NAME"
            aws iam delete-role --role-name "$RUNTIME_ROLE_NAME"
        fi
        
        # Detach policies and delete admin role if it exists
        if [ -n "$ADMIN_ROLE_NAME" ]; then
            echo "Detaching policy from role: $ADMIN_ROLE_NAME"
            aws iam detach-role-policy --role-name "$ADMIN_ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
            
            echo "Deleting IAM role: $ADMIN_ROLE_NAME"
            aws iam delete-role --role-name "$ADMIN_ROLE_NAME"
        fi
        
        echo "Cleanup completed."
    else
        echo "Resources will not be deleted."
    fi
}

# Trap to ensure cleanup on script exit
trap 'echo "Script interrupted. Running cleanup..."; cleanup_resources' INT TERM

# Generate random identifiers for resources
ADMIN_ROLE_NAME="SecretsManagerAdmin-$(generate_random_id)"
RUNTIME_ROLE_NAME="RoleToRetrieveSecretAtRuntime-$(generate_random_id)"
SECRET_NAME="MyAPIKey-$(generate_random_id)"

echo "Using the following resource names:"
echo "Admin Role: $ADMIN_ROLE_NAME"
echo "Runtime Role: $RUNTIME_ROLE_NAME"
echo "Secret Name: $SECRET_NAME"
echo ""

# Step 1: Create IAM roles
echo "Creating IAM roles..."

# Create the SecretsManagerAdmin role
echo "Creating admin role: $ADMIN_ROLE_NAME"
ADMIN_ROLE_OUTPUT=$(aws iam create-role \
    --role-name "$ADMIN_ROLE_NAME" \
    --assume-role-policy-document '{
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
    }')

check_error "$ADMIN_ROLE_OUTPUT" "create-role for admin"
echo "$ADMIN_ROLE_OUTPUT"

# Attach the SecretsManagerReadWrite policy to the admin role
echo "Attaching SecretsManagerReadWrite policy to admin role"
ATTACH_POLICY_OUTPUT=$(aws iam attach-role-policy \
    --role-name "$ADMIN_ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/SecretsManagerReadWrite")

check_error "$ATTACH_POLICY_OUTPUT" "attach-role-policy for admin"
echo "$ATTACH_POLICY_OUTPUT"

# Create the RoleToRetrieveSecretAtRuntime role
echo "Creating runtime role: $RUNTIME_ROLE_NAME"
RUNTIME_ROLE_OUTPUT=$(aws iam create-role \
    --role-name "$RUNTIME_ROLE_NAME" \
    --assume-role-policy-document '{
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
    }')

check_error "$RUNTIME_ROLE_OUTPUT" "create-role for runtime"
echo "$RUNTIME_ROLE_OUTPUT"

# Wait for roles to be fully created
echo "Waiting for IAM roles to be fully created..."
sleep 10

# Step 2: Create a secret in AWS Secrets Manager
echo "Creating secret in AWS Secrets Manager..."

CREATE_SECRET_OUTPUT=$(aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "API key for my application" \
    --secret-string '{"ClientID":"my_client_id","ClientSecret":"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"}')

check_error "$CREATE_SECRET_OUTPUT" "create-secret"
echo "$CREATE_SECRET_OUTPUT"

# Get AWS account ID
echo "Getting AWS account ID..."
ACCOUNT_ID_OUTPUT=$(aws sts get-caller-identity --query "Account" --output text)
check_error "$ACCOUNT_ID_OUTPUT" "get-caller-identity"
ACCOUNT_ID=$ACCOUNT_ID_OUTPUT
echo "Account ID: $ACCOUNT_ID"

# Add resource policy to the secret
echo "Adding resource policy to secret..."
RESOURCE_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$ACCOUNT_ID:role/$RUNTIME_ROLE_NAME"
            },
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "*"
        }
    ]
}
EOF
)

PUT_POLICY_OUTPUT=$(aws secretsmanager put-resource-policy \
    --secret-id "$SECRET_NAME" \
    --resource-policy "$RESOURCE_POLICY" \
    --block-public-policy)

check_error "$PUT_POLICY_OUTPUT" "put-resource-policy"
echo "$PUT_POLICY_OUTPUT"

# Step 3: Demonstrate retrieving the secret
echo "Retrieving the secret value (for demonstration purposes)..."
GET_SECRET_OUTPUT=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME")

check_error "$GET_SECRET_OUTPUT" "get-secret-value"
echo "Secret retrieved successfully. Secret metadata:"
echo "$GET_SECRET_OUTPUT" | grep -v "SecretString"

# Step 4: Update the secret with new values
echo "Updating the secret with new values..."
UPDATE_SECRET_OUTPUT=$(aws secretsmanager update-secret \
    --secret-id "$SECRET_NAME" \
    --secret-string '{"ClientID":"my_new_client_id","ClientSecret":"bPxRfiCYEXAMPLEKEY/wJalrXUtnFEMI/K7MDENG"}')

check_error "$UPDATE_SECRET_OUTPUT" "update-secret"
echo "$UPDATE_SECRET_OUTPUT"

# Step 5: Verify the updated secret
echo "Verifying the updated secret..."
VERIFY_SECRET_OUTPUT=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME")

check_error "$VERIFY_SECRET_OUTPUT" "get-secret-value for verification"
echo "Updated secret retrieved successfully. Secret metadata:"
echo "$VERIFY_SECRET_OUTPUT" | grep -v "SecretString"

echo ""
echo "======================================================"
echo "Tutorial completed successfully!"
echo ""
echo "Summary of what we did:"
echo "1. Created IAM roles for managing and retrieving secrets"
echo "2. Created a secret in AWS Secrets Manager"
echo "3. Added a resource policy to control access to the secret"
echo "4. Retrieved the secret value (simulating application access)"
echo "5. Updated the secret with new values"
echo ""
echo "Next steps you might want to consider:"
echo "- Implement secret caching in your application"
echo "- Set up automatic rotation for your secrets"
echo "- Use AWS CodeGuru Reviewer to find hardcoded secrets in your code"
echo "- For multi-region applications, replicate your secrets across regions"
echo ""

# Clean up resources
cleanup_resources

echo "Script completed at $(date)"
exit 0
