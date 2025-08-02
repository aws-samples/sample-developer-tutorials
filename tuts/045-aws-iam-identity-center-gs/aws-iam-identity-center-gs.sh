#!/bin/bash

# IAM Identity Center Setup Script - Version 11 (Final Fixed)
# This script sets up IAM Identity Center with a default identity source,
# creates users and groups, and configures permissions.
#
# Fixes in this version:
# - Fixed application creation with working OAuth application provider ARN
# - Fixed permission set provisioning status check parameter name
# - Fixed portal URL construction using Identity Store ID
# - Added proper waiting for provisioning operations to complete
# - Improved error handling for asynchronous operations

# Initialize log file
LOG_FILE="idc_setup_$(date +%Y%m%d_%H%M%S).log"
echo "Starting IAM Identity Center setup at $(date)" > "$LOG_FILE"

# Function to log commands and their output
log_cmd() {
    echo "$(date): COMMAND: $1" >> "$LOG_FILE"
    eval "$1" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# Function to check for errors in command output
check_error() {
    local cmd_output="$1"
    local cmd_status="$2"
    local error_msg="$3"
    local ignore_error="${4:-false}"
    
    if [[ $cmd_status -ne 0 || "$cmd_output" =~ [Ee][Rr][Rr][Oo][Rr] ]]; then
        if [[ "$ignore_error" == "true" ]]; then
            echo "WARNING: $error_msg (continuing)" | tee -a "$LOG_FILE"
            return 1
        else
            echo "ERROR: $error_msg" | tee -a "$LOG_FILE"
            cleanup_resources
            exit 1
        fi
    fi
    return 0
}

# Function to wait for provisioning operation to complete
wait_for_provisioning() {
    local instance_arn="$1"
    local request_id="$2"
    local operation_type="$3"
    local max_attempts=30
    local attempt=1
    
    echo "Waiting for $operation_type to complete (Request ID: $request_id)..." | tee -a "$LOG_FILE"
    
    while [[ $attempt -le $max_attempts ]]; do
        case "$operation_type" in
            "permission_set_provisioning")
                STATUS_OUTPUT=$(log_cmd "aws sso-admin describe-permission-set-provisioning-status --instance-arn \"$instance_arn\" --provision-permission-set-request-id \"$request_id\" --query 'PermissionSetProvisioningStatus.Status' --output text")
                ;;
            "account_assignment_creation")
                STATUS_OUTPUT=$(log_cmd "aws sso-admin describe-account-assignment-creation-status --instance-arn \"$instance_arn\" --account-assignment-creation-request-id \"$request_id\" --query 'AccountAssignmentCreationStatus.Status' --output text")
                ;;
            "account_assignment_deletion")
                STATUS_OUTPUT=$(log_cmd "aws sso-admin describe-account-assignment-deletion-status --instance-arn \"$instance_arn\" --account-assignment-deletion-request-id \"$request_id\" --query 'AccountAssignmentDeletionStatus.Status' --output text")
                ;;
        esac
        
        if [[ "$STATUS_OUTPUT" == "SUCCEEDED" ]]; then
            echo "$operation_type completed successfully" | tee -a "$LOG_FILE"
            return 0
        elif [[ "$STATUS_OUTPUT" == "FAILED" ]]; then
            echo "ERROR: $operation_type failed" | tee -a "$LOG_FILE"
            return 1
        elif [[ "$STATUS_OUTPUT" == "IN_PROGRESS" ]]; then
            echo "Attempt $attempt/$max_attempts: $operation_type still in progress..." | tee -a "$LOG_FILE"
            sleep 10
            ((attempt++))
        else
            echo "WARNING: Unknown status: $STATUS_OUTPUT" | tee -a "$LOG_FILE"
            sleep 10
            ((attempt++))
        fi
    done
    
    echo "WARNING: $operation_type did not complete within expected time" | tee -a "$LOG_FILE"
    return 1
}

# Array to track created resources for cleanup
declare -a CREATED_RESOURCES

# Function to add a resource to the tracking array
track_resource() {
    local resource_type="$1"
    local resource_id="$2"
    CREATED_RESOURCES+=("$resource_type:$resource_id")
    echo "Tracked resource: $resource_type:$resource_id" >> "$LOG_FILE"
}

# Function to clean up resources
cleanup_resources() {
    echo "" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    echo "CLEANUP PROCESS" | tee -a "$LOG_FILE"
    echo "===========================================================" | tee -a "$LOG_FILE"
    
    # Reverse the array to delete resources in reverse order of creation
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=':' read -r resource_type resource_id <<< "${CREATED_RESOURCES[$i]}"
        echo "Deleting $resource_type: $resource_id" | tee -a "$LOG_FILE"
        
        case "$resource_type" in
            "account_assignment")
                IFS=',' read -r instance_arn permission_set_arn target_id principal_id principal_type <<< "$resource_id"
                DELETE_OUTPUT=$(log_cmd "aws sso-admin delete-account-assignment --instance-arn \"$instance_arn\" --permission-set-arn \"$permission_set_arn\" --target-id \"$target_id\" --target-type AWS_ACCOUNT --principal-id \"$principal_id\" --principal-type \"$principal_type\"")
                # Extract request ID and wait for completion
                REQUEST_ID=$(echo "$DELETE_OUTPUT" | grep -o '"RequestId": "[^"]*' | cut -d'"' -f4)
                if [[ -n "$REQUEST_ID" ]]; then
                    wait_for_provisioning "$instance_arn" "$REQUEST_ID" "account_assignment_deletion"
                fi
                ;;
            "group_membership")
                IFS=',' read -r identity_store_id group_id membership_id <<< "$resource_id"
                log_cmd "aws identitystore delete-group-membership --identity-store-id \"$identity_store_id\" --membership-id \"$membership_id\""
                ;;
            "group")
                IFS=',' read -r identity_store_id group_id <<< "$resource_id"
                log_cmd "aws identitystore delete-group --identity-store-id \"$identity_store_id\" --group-id \"$group_id\""
                ;;
            "user")
                IFS=',' read -r identity_store_id user_id <<< "$resource_id"
                log_cmd "aws identitystore delete-user --identity-store-id \"$identity_store_id\" --user-id \"$user_id\""
                ;;
            "managed_policy")
                IFS=',' read -r instance_arn permission_set_arn policy_arn <<< "$resource_id"
                log_cmd "aws sso-admin detach-managed-policy-from-permission-set --instance-arn \"$instance_arn\" --permission-set-arn \"$permission_set_arn\" --managed-policy-arn \"$policy_arn\""
                ;;
            "permission_set")
                IFS=',' read -r instance_arn permission_set_arn <<< "$resource_id"
                log_cmd "aws sso-admin delete-permission-set --instance-arn \"$instance_arn\" --permission-set-arn \"$permission_set_arn\""
                ;;
            "application_assignment")
                IFS=',' read -r application_arn principal_id principal_type <<< "$resource_id"
                log_cmd "aws sso-admin delete-application-assignment --application-arn \"$application_arn\" --principal-id \"$principal_id\" --principal-type \"$principal_type\""
                ;;
            "application")
                log_cmd "aws sso-admin delete-application --application-arn \"$resource_id\""
                ;;
            *)
                echo "Unknown resource type: $resource_type" | tee -a "$LOG_FILE"
                ;;
        esac
        
        # Sleep briefly to allow AWS to process the deletion
        sleep 2
    done
    
    echo "Cleanup completed." | tee -a "$LOG_FILE"
}

# Function to display help information
show_help() {
    echo "IAM Identity Center Setup Script - Version 11 (Final Fixed)"
    echo ""
    echo "This script sets up IAM Identity Center with users, groups, and permissions."
    echo ""
    echo "Prerequisites:"
    echo "- For organization management accounts: Enable IAM Identity Center through the AWS Console first"
    echo "- For standalone accounts: The script can create an account instance"
    echo "- AWS CLI must be configured with appropriate permissions"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --skip-enable  Skip the IAM Identity Center enablement check (assumes already enabled)"
    echo ""
    echo "To enable IAM Identity Center for organization management accounts:"
    echo "1. Go to: https://console.aws.amazon.com/singlesignon"
    echo "2. Click 'Enable' to enable IAM Identity Center for your organization"
    echo "3. Run this script with --skip-enable flag"
    echo ""
}

# Parse command line arguments
SKIP_ENABLE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --skip-enable)
            SKIP_ENABLE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main script execution
echo "===========================================================" | tee -a "$LOG_FILE"
echo "IAM Identity Center Setup Script - Version 11 (Final Fixed)" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check if the AWS account is part of an organization
echo "Checking if the AWS account is part of an organization..." | tee -a "$LOG_FILE"
ORG_CHECK=$(log_cmd "aws organizations describe-organization 2>&1")
IS_ORG_MEMBER=false
IS_ORG_MANAGEMENT=false

if [[ ! "$ORG_CHECK" =~ "AccessDenied" && ! "$ORG_CHECK" =~ "AWSOrganizationsNotInUseException" ]]; then
    IS_ORG_MEMBER=true
    
    # Check if this is the management account
    ACCOUNT_ID=$(log_cmd "aws sts get-caller-identity --query 'Account' --output text")
    MANAGEMENT_ACCOUNT_ID=$(echo "$ORG_CHECK" | grep -o '"MasterAccountId": "[^"]*' | cut -d'"' -f4)
    
    if [[ "$ACCOUNT_ID" == "$MANAGEMENT_ACCOUNT_ID" ]]; then
        IS_ORG_MANAGEMENT=true
        echo "This is the organization management account." | tee -a "$LOG_FILE"
    else
        echo "This is a member account in an organization." | tee -a "$LOG_FILE"
    fi
else
    echo "This account is not part of an organization." | tee -a "$LOG_FILE"
fi

# Step 1: Check if IAM Identity Center is already enabled or handle enablement
echo "Checking if IAM Identity Center is already enabled..." | tee -a "$LOG_FILE"
INSTANCES_OUTPUT=$(log_cmd "aws sso-admin list-instances --query 'Instances[*]' --output json")
check_error "$INSTANCES_OUTPUT" $? "Failed to list IAM Identity Center instances"

INSTANCE_COUNT=$(echo "$INSTANCES_OUTPUT" | grep -c "InstanceArn")
if [[ $INSTANCE_COUNT -gt 0 ]]; then
    echo "IAM Identity Center is already enabled. Using existing instance." | tee -a "$LOG_FILE"
    INSTANCE_ARN=$(echo "$INSTANCES_OUTPUT" | grep -o '"InstanceArn": "[^"]*' | cut -d'"' -f4 | head -1)
    IDENTITY_STORE_ID=$(echo "$INSTANCES_OUTPUT" | grep -o '"IdentityStoreId": "[^"]*' | cut -d'"' -f4 | head -1)
    
    # Determine instance type based on organization status
    if [[ "$IS_ORG_MEMBER" == "true" && "$IS_ORG_MANAGEMENT" == "true" ]]; then
        IS_ORGANIZATION_INSTANCE=true
        echo "This is an organization instance of IAM Identity Center." | tee -a "$LOG_FILE"
    else
        IS_ORGANIZATION_INSTANCE=false
        echo "This is an account instance of IAM Identity Center." | tee -a "$LOG_FILE"
    fi
else
    if [[ "$SKIP_ENABLE" == "true" ]]; then
        echo "ERROR: --skip-enable flag was used but no IAM Identity Center instance was found." | tee -a "$LOG_FILE"
        echo "Please enable IAM Identity Center first or remove the --skip-enable flag." | tee -a "$LOG_FILE"
        exit 1
    fi
    
    if [[ "$IS_ORG_MANAGEMENT" == "true" ]]; then
        echo "ERROR: IAM Identity Center is not enabled for this organization." | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        echo "For organization management accounts, IAM Identity Center must be enabled through the AWS Console." | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        echo "Steps to enable IAM Identity Center:" | tee -a "$LOG_FILE"
        echo "1. Go to the AWS Console: https://console.aws.amazon.com/" | tee -a "$LOG_FILE"
        echo "2. Navigate to IAM Identity Center: https://console.aws.amazon.com/singlesignon" | tee -a "$LOG_FILE"
        echo "3. Click 'Enable' to enable IAM Identity Center for your organization" | tee -a "$LOG_FILE"
        echo "4. Once enabled, run this script again with --skip-enable flag" | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        echo "Example: $0 --skip-enable" | tee -a "$LOG_FILE"
        exit 1
    else
        echo "Creating a new IAM Identity Center instance..." | tee -a "$LOG_FILE"
        
        # Create IAM Identity Center instance (only works for non-organization management accounts)
        INSTANCE_OUTPUT=$(log_cmd "aws sso-admin create-instance --name \"MyIdentityCenter\" --tags Key=Purpose,Value=Tutorial")
        check_error "$INSTANCE_OUTPUT" $? "Failed to create IAM Identity Center instance"
        
        # Wait for instance to be created and get instance ARN
        echo "Waiting for IAM Identity Center instance to be created..." | tee -a "$LOG_FILE"
        sleep 10
        
        INSTANCES_OUTPUT=$(log_cmd "aws sso-admin list-instances --query 'Instances[*]' --output json")
        check_error "$INSTANCES_OUTPUT" $? "Failed to list IAM Identity Center instances after creation"
        
        INSTANCE_ARN=$(echo "$INSTANCES_OUTPUT" | grep -o '"InstanceArn": "[^"]*' | cut -d'"' -f4 | head -1)
        IDENTITY_STORE_ID=$(echo "$INSTANCES_OUTPUT" | grep -o '"IdentityStoreId": "[^"]*' | cut -d'"' -f4 | head -1)
        
        if [[ -z "$INSTANCE_ARN" || -z "$IDENTITY_STORE_ID" ]]; then
            echo "ERROR: Failed to retrieve instance ARN or identity store ID" | tee -a "$LOG_FILE"
            exit 1
        fi
        
        echo "IAM Identity Center instance created successfully." | tee -a "$LOG_FILE"
        echo "Instance ARN: $INSTANCE_ARN" | tee -a "$LOG_FILE"
        echo "Identity Store ID: $IDENTITY_STORE_ID" | tee -a "$LOG_FILE"
        
        IS_ORGANIZATION_INSTANCE=false
        echo "Created an account instance of IAM Identity Center." | tee -a "$LOG_FILE"
        
        # Give the instance some time to initialize
        echo "Waiting for IAM Identity Center instance to initialize..." | tee -a "$LOG_FILE"
        sleep 30
    fi
fi

# Step 2: Create a user in IAM Identity Center
echo "" | tee -a "$LOG_FILE"
echo "Creating a user in IAM Identity Center..." | tee -a "$LOG_FILE"

# Generate a random username suffix for uniqueness
USERNAME_SUFFIX=$(openssl rand -hex 4)
USERNAME="user-${USERNAME_SUFFIX}"
DISPLAY_NAME="Demo User"
EMAIL="${USERNAME}@example.com"

USER_OUTPUT=$(log_cmd "aws identitystore create-user \
  --identity-store-id \"$IDENTITY_STORE_ID\" \
  --user-name \"$USERNAME\" \
  --display-name \"$DISPLAY_NAME\" \
  --name \"GivenName=Demo,FamilyName=User\" \
  --emails \"Value=$EMAIL,Type=Work,Primary=true\"")
check_error "$USER_OUTPUT" $? "Failed to create user"

USER_ID=$(echo "$USER_OUTPUT" | grep -o '"UserId": "[^"]*' | cut -d'"' -f4)
if [[ -z "$USER_ID" ]]; then
    echo "ERROR: Failed to retrieve user ID" | tee -a "$LOG_FILE"
    cleanup_resources
    exit 1
fi

track_resource "user" "$IDENTITY_STORE_ID,$USER_ID"
echo "User created successfully with ID: $USER_ID" | tee -a "$LOG_FILE"

# Step 3: Create a group in IAM Identity Center
echo "" | tee -a "$LOG_FILE"
echo "Creating a group in IAM Identity Center..." | tee -a "$LOG_FILE"

# Generate a random group name suffix for uniqueness
GROUP_SUFFIX=$(openssl rand -hex 4)
GROUP_NAME="Developers-${GROUP_SUFFIX}"

GROUP_OUTPUT=$(log_cmd "aws identitystore create-group \
  --identity-store-id \"$IDENTITY_STORE_ID\" \
  --display-name \"$GROUP_NAME\" \
  --description \"Development team members\"")
check_error "$GROUP_OUTPUT" $? "Failed to create group"

GROUP_ID=$(echo "$GROUP_OUTPUT" | grep -o '"GroupId": "[^"]*' | cut -d'"' -f4)
if [[ -z "$GROUP_ID" ]]; then
    echo "ERROR: Failed to retrieve group ID" | tee -a "$LOG_FILE"
    cleanup_resources
    exit 1
fi

track_resource "group" "$IDENTITY_STORE_ID,$GROUP_ID"
echo "Group created successfully with ID: $GROUP_ID" | tee -a "$LOG_FILE"

# Step 4: Add user to group
echo "" | tee -a "$LOG_FILE"
echo "Adding user to group..." | tee -a "$LOG_FILE"

MEMBERSHIP_OUTPUT=$(log_cmd "aws identitystore create-group-membership \
  --identity-store-id \"$IDENTITY_STORE_ID\" \
  --group-id \"$GROUP_ID\" \
  --member-id \"UserId=$USER_ID\"")
check_error "$MEMBERSHIP_OUTPUT" $? "Failed to add user to group"

MEMBERSHIP_ID=$(echo "$MEMBERSHIP_OUTPUT" | grep -o '"MembershipId": "[^"]*' | cut -d'"' -f4)
if [[ -z "$MEMBERSHIP_ID" ]]; then
    echo "ERROR: Failed to retrieve membership ID" | tee -a "$LOG_FILE"
    cleanup_resources
    exit 1
fi

track_resource "group_membership" "$IDENTITY_STORE_ID,$GROUP_ID,$MEMBERSHIP_ID"
echo "User added to group successfully with membership ID: $MEMBERSHIP_ID" | tee -a "$LOG_FILE"

# Steps 5-9: Set up AWS account access (only for organization instances)
if [[ "$IS_ORGANIZATION_INSTANCE" == "true" ]]; then
    echo "" | tee -a "$LOG_FILE"
    echo "Setting up AWS account access (organization instance only)..." | tee -a "$LOG_FILE"
    
    # Step 5: Create a permission set
    echo "Creating a permission set..." | tee -a "$LOG_FILE"
    
    # Generate a random permission set name suffix for uniqueness
    PS_SUFFIX=$(openssl rand -hex 4)
    PS_NAME="DeveloperAccess-${PS_SUFFIX}"
    
    PS_OUTPUT=$(log_cmd "aws sso-admin create-permission-set \
      --instance-arn \"$INSTANCE_ARN\" \
      --name \"$PS_NAME\" \
      --description \"Developer access to AWS resources\" \
      --session-duration \"PT8H\"")
    check_error "$PS_OUTPUT" $? "Failed to create permission set"
    
    PERMISSION_SET_ARN=$(echo "$PS_OUTPUT" | grep -o '"PermissionSetArn": "[^"]*' | cut -d'"' -f4)
    if [[ -z "$PERMISSION_SET_ARN" ]]; then
        echo "ERROR: Failed to retrieve permission set ARN" | tee -a "$LOG_FILE"
        cleanup_resources
        exit 1
    fi
    
    track_resource "permission_set" "$INSTANCE_ARN,$PERMISSION_SET_ARN"
    echo "Permission set created successfully with ARN: $PERMISSION_SET_ARN" | tee -a "$LOG_FILE"
    
    # Step 6: Attach AWS managed policy to permission set
    echo "Attaching AWS managed policy to permission set..." | tee -a "$LOG_FILE"
    
    POLICY_OUTPUT=$(log_cmd "aws sso-admin attach-managed-policy-to-permission-set \
      --instance-arn \"$INSTANCE_ARN\" \
      --permission-set-arn \"$PERMISSION_SET_ARN\" \
      --managed-policy-arn \"arn:aws:iam::aws:policy/ReadOnlyAccess\"")
    check_error "$POLICY_OUTPUT" $? "Failed to attach managed policy to permission set"
    
    track_resource "managed_policy" "$INSTANCE_ARN,$PERMISSION_SET_ARN,arn:aws:iam::aws:policy/ReadOnlyAccess"
    echo "AWS managed policy attached successfully" | tee -a "$LOG_FILE"
    
    # Step 7: Get the AWS account ID
    echo "Getting AWS account ID..." | tee -a "$LOG_FILE"
    
    ACCOUNT_OUTPUT=$(log_cmd "aws sts get-caller-identity --query 'Account' --output text")
    check_error "$ACCOUNT_OUTPUT" $? "Failed to get AWS account ID"
    
    AWS_ACCOUNT_ID=$(echo "$ACCOUNT_OUTPUT" | tr -d '\n')
    echo "AWS Account ID: $AWS_ACCOUNT_ID" | tee -a "$LOG_FILE"
    
    # Step 8: Assign group to AWS account with permission set
    echo "Assigning group to AWS account with permission set..." | tee -a "$LOG_FILE"
    
    ASSIGNMENT_OUTPUT=$(log_cmd "aws sso-admin create-account-assignment \
      --instance-arn \"$INSTANCE_ARN\" \
      --target-id \"$AWS_ACCOUNT_ID\" \
      --target-type AWS_ACCOUNT \
      --principal-type GROUP \
      --principal-id \"$GROUP_ID\" \
      --permission-set-arn \"$PERMISSION_SET_ARN\"")
    check_error "$ASSIGNMENT_OUTPUT" $? "Failed to assign group to AWS account"
    
    # Extract request ID and wait for completion
    ASSIGNMENT_REQUEST_ID=$(echo "$ASSIGNMENT_OUTPUT" | grep -o '"RequestId": "[^"]*' | cut -d'"' -f4)
    if [[ -n "$ASSIGNMENT_REQUEST_ID" ]]; then
        wait_for_provisioning "$INSTANCE_ARN" "$ASSIGNMENT_REQUEST_ID" "account_assignment_creation"
        if [[ $? -eq 0 ]]; then
            track_resource "account_assignment" "$INSTANCE_ARN,$PERMISSION_SET_ARN,$AWS_ACCOUNT_ID,$GROUP_ID,GROUP"
            echo "Group assigned to AWS account successfully" | tee -a "$LOG_FILE"
        else
            echo "ERROR: Account assignment failed" | tee -a "$LOG_FILE"
            cleanup_resources
            exit 1
        fi
    else
        echo "WARNING: Could not extract assignment request ID" | tee -a "$LOG_FILE"
        track_resource "account_assignment" "$INSTANCE_ARN,$PERMISSION_SET_ARN,$AWS_ACCOUNT_ID,$GROUP_ID,GROUP"
    fi
    
    # Step 9: Provision the permission set to the account
    echo "Provisioning permission set to the account..." | tee -a "$LOG_FILE"
    
    PROVISION_OUTPUT=$(log_cmd "aws sso-admin provision-permission-set \
      --instance-arn \"$INSTANCE_ARN\" \
      --permission-set-arn \"$PERMISSION_SET_ARN\" \
      --target-id \"$AWS_ACCOUNT_ID\" \
      --target-type AWS_ACCOUNT")
    check_error "$PROVISION_OUTPUT" $? "Failed to provision permission set"
    
    # Extract request ID and wait for completion
    PROVISION_REQUEST_ID=$(echo "$PROVISION_OUTPUT" | grep -o '"RequestId": "[^"]*' | cut -d'"' -f4)
    if [[ -n "$PROVISION_REQUEST_ID" ]]; then
        wait_for_provisioning "$INSTANCE_ARN" "$PROVISION_REQUEST_ID" "permission_set_provisioning"
        if [[ $? -eq 0 ]]; then
            echo "Permission set provisioned successfully" | tee -a "$LOG_FILE"
        else
            echo "ERROR: Permission set provisioning failed" | tee -a "$LOG_FILE"
            cleanup_resources
            exit 1
        fi
    else
        echo "WARNING: Could not extract provisioning request ID" | tee -a "$LOG_FILE"
    fi
else
    echo "" | tee -a "$LOG_FILE"
    echo "Skipping AWS account access setup (requires organization instance)" | tee -a "$LOG_FILE"
fi

# Step 10: Create an application (using a SAML application provider)
echo "" | tee -a "$LOG_FILE"
echo "Creating an application..." | tee -a "$LOG_FILE"

# Generate a random application name suffix for uniqueness
APP_SUFFIX=$(openssl rand -hex 4)
APP_NAME="MyCustomApp-${APP_SUFFIX}"

# Use the custom OAuth application provider that supports create-application
APP_PROVIDER_ARN="arn:aws:sso::aws:applicationProvider/custom"

APP_OUTPUT=$(log_cmd "aws sso-admin create-application \
  --instance-arn \"$INSTANCE_ARN\" \
  --application-provider-arn \"$APP_PROVIDER_ARN\" \
  --name \"$APP_NAME\" \
  --description \"My custom OAuth application for demonstration\" \
  --portal-options Visibility=ENABLED")
if ! check_error "$APP_OUTPUT" $? "Failed to create application" "true"; then
    echo "Skipping application creation and assignment steps" | tee -a "$LOG_FILE"
    HAS_APPLICATION=false
else
    HAS_APPLICATION=true
    
    APPLICATION_ARN=$(echo "$APP_OUTPUT" | grep -o '"ApplicationArn": "[^"]*' | cut -d'"' -f4)
    if [[ -z "$APPLICATION_ARN" ]]; then
        echo "ERROR: Failed to retrieve application ARN" | tee -a "$LOG_FILE"
        cleanup_resources
        exit 1
    fi
    
    track_resource "application" "$APPLICATION_ARN"
    echo "Application created successfully with ARN: $APPLICATION_ARN" | tee -a "$LOG_FILE"
    
    # Step 11: Assign user to application
    echo "" | tee -a "$LOG_FILE"
    echo "Assigning user to application..." | tee -a "$LOG_FILE"
    
    APP_ASSIGNMENT_OUTPUT=$(log_cmd "aws sso-admin create-application-assignment \
      --application-arn \"$APPLICATION_ARN\" \
      --principal-type USER \
      --principal-id \"$USER_ID\"")
    check_error "$APP_ASSIGNMENT_OUTPUT" $? "Failed to assign user to application"
    
    track_resource "application_assignment" "$APPLICATION_ARN,$USER_ID,USER"
    echo "User assigned to application successfully" | tee -a "$LOG_FILE"
fi

# Step 12: Get the AWS access portal URL
echo "" | tee -a "$LOG_FILE"
echo "Getting the AWS access portal URL..." | tee -a "$LOG_FILE"

# Construct the portal URL using the Identity Store ID
# Format: https://d-xxxxxxxxxx.awsapps.com/start
PORTAL_URL="https://${IDENTITY_STORE_ID}.awsapps.com/start"
echo "AWS access portal URL: $PORTAL_URL" | tee -a "$LOG_FILE"

# Summary of created resources
echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "SETUP SUMMARY" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "IAM Identity Center has been set up successfully!" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Resources created:" | tee -a "$LOG_FILE"
echo "- User: $USERNAME (ID: $USER_ID)" | tee -a "$LOG_FILE"
echo "- Group: $GROUP_NAME (ID: $GROUP_ID)" | tee -a "$LOG_FILE"

if [[ "$IS_ORGANIZATION_INSTANCE" == "true" ]]; then
    echo "- Permission set: $PS_NAME" | tee -a "$LOG_FILE"
fi

if [[ "$HAS_APPLICATION" == "true" ]]; then
    echo "- Application: $APP_NAME" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "AWS access portal URL: $PORTAL_URL" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Ask if user wants to clean up resources
echo "" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "CLEANUP CONFIRMATION" | tee -a "$LOG_FILE"
echo "===========================================================" | tee -a "$LOG_FILE"
echo "Do you want to clean up all created resources? (y/n): " | tee -a "$LOG_FILE"
read -r CLEANUP_CHOICE
echo "$CLEANUP_CHOICE" >> "$LOG_FILE"

if [[ "$CLEANUP_CHOICE" =~ ^[Yy] ]]; then
    cleanup_resources
else
    echo "Resources will be preserved. You can manually clean them up later." | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "Script completed at $(date)" | tee -a "$LOG_FILE"
