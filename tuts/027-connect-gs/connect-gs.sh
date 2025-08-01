#!/bin/bash

# Script to create an Amazon Connect instance using AWS CLI
# This script follows the steps in the Amazon Connect instance creation tutorial

# Set up logging
LOG_FILE="connect-instance-creation.log"
echo "Starting Amazon Connect instance creation at $(date)" > "$LOG_FILE"

# Set default region
AWS_REGION="us-west-2"
echo "Using AWS region: $AWS_REGION" | tee -a "$LOG_FILE"

# Function to log commands and their output
log_cmd() {
    echo "$(date): Running command: $1" >> "$LOG_FILE"
    eval "$1" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# Function to check for errors in command output
check_error() {
    local cmd_output="$1"
    local cmd_status="$2"
    local error_msg="$3"
    
    if [[ $cmd_status -ne 0 || "$cmd_output" =~ [Ee][Rr][Rr][Oo][Rr] ]]; then
        echo "ERROR: $error_msg" | tee -a "$LOG_FILE"
        return 1
    fi
    return 0
}

# Function to clean up resources on error
cleanup_on_error() {
    echo "Error encountered. Attempting to clean up resources..." | tee -a "$LOG_FILE"
    
    if [[ -n "$INSTANCE_ID" ]]; then
        echo "Deleting Amazon Connect instance: $INSTANCE_ID" | tee -a "$LOG_FILE"
        log_cmd "aws connect delete-instance --instance-id $INSTANCE_ID --region $AWS_REGION"
    fi
    
    echo "Cleanup completed. See $LOG_FILE for details." | tee -a "$LOG_FILE"
}

# Function to wait for instance to be fully active
wait_for_instance() {
    local instance_id="$1"
    local max_attempts=30
    local attempt=1
    
    echo "Waiting for instance $instance_id to become fully active..." | tee -a "$LOG_FILE"
    
    while [[ $attempt -le $max_attempts ]]; do
        echo "Attempt $attempt of $max_attempts: Checking instance status..." | tee -a "$LOG_FILE"
        
        # Try to describe the instance
        local result=$(log_cmd "aws connect describe-instance --instance-id $instance_id --region $AWS_REGION --output json")
        
        # Check if the command was successful and instance status is ACTIVE
        if [[ $? -eq 0 && "$result" =~ "ACTIVE" ]]; then
            echo "Instance is now fully active and ready to use." | tee -a "$LOG_FILE"
            return 0
        fi
        
        echo "Instance not fully active yet. Waiting 30 seconds before next check..." | tee -a "$LOG_FILE"
        sleep 30
        ((attempt++))
    done
    
    echo "Timed out waiting for instance to become fully active." | tee -a "$LOG_FILE"
    return 1
}

# Function to check and handle existing instances
check_existing_instances() {
    echo "Checking for existing Amazon Connect instances..." | tee -a "$LOG_FILE"
    
    local instances=$(log_cmd "aws connect list-instances --region $AWS_REGION --output json")
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to list existing instances" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Check if there are any instances
    local instance_count=$(echo "$instances" | grep -o '"Id":' | wc -l)
    
    if [[ $instance_count -gt 0 ]]; then
        echo "Found $instance_count existing Amazon Connect instance(s)" | tee -a "$LOG_FILE"
        echo "$instances" | grep -A 1 '"Id":' | tee -a "$LOG_FILE"
        
        echo ""
        echo "==========================================="
        echo "EXISTING INSTANCES FOUND"
        echo "==========================================="
        echo "Found $instance_count existing Amazon Connect instance(s)."
        echo "Do you want to delete these instances to free up quota? (y/n): "
        read -r DELETE_CHOICE
        
        if [[ "$DELETE_CHOICE" =~ ^[Yy] ]]; then
            echo "Deleting existing instances..." | tee -a "$LOG_FILE"
            
            # Extract instance IDs and delete each one
            local instance_ids=($(echo "$instances" | grep -o '"Id": "[^"]*' | cut -d'"' -f4))
            
            for id in "${instance_ids[@]}"; do
                echo "Deleting instance: $id" | tee -a "$LOG_FILE"
                log_cmd "aws connect delete-instance --instance-id $id --region $AWS_REGION"
                
                if [[ $? -ne 0 ]]; then
                    echo "WARNING: Failed to delete instance $id" | tee -a "$LOG_FILE"
                else
                    echo "Successfully deleted instance $id" | tee -a "$LOG_FILE"
                fi
                
                # Wait a bit between deletions
                sleep 5
            done
            
            echo "Waiting for deletions to complete..." | tee -a "$LOG_FILE"
            sleep 30
        else
            echo "Keeping existing instances. Script may fail if quota is reached." | tee -a "$LOG_FILE"
        fi
    else
        echo "No existing Amazon Connect instances found" | tee -a "$LOG_FILE"
    fi
    
    return 0
}

# Check for existing instances before proceeding
check_existing_instances

# Generate a random instance alias to avoid naming conflicts
INSTANCE_ALIAS="connect-instance-$(openssl rand -hex 6)"
echo "Using instance alias: $INSTANCE_ALIAS" | tee -a "$LOG_FILE"

# Step 1: Create Amazon Connect instance
echo "Step 1: Creating Amazon Connect instance..." | tee -a "$LOG_FILE"
INSTANCE_RESULT=$(log_cmd "aws connect create-instance --identity-management-type CONNECT_MANAGED --instance-alias $INSTANCE_ALIAS --inbound-calls-enabled --outbound-calls-enabled --region $AWS_REGION --output json")

if ! check_error "$INSTANCE_RESULT" $? "Failed to create Amazon Connect instance"; then
    # Check if the error is due to quota limit
    if [[ "$INSTANCE_RESULT" =~ "ServiceQuotaExceededException" || "$INSTANCE_RESULT" =~ "Quota limit reached" ]]; then
        echo "Quota limit reached for Amazon Connect instances. Please delete existing instances or request a quota increase." | tee -a "$LOG_FILE"
    fi
    cleanup_on_error
    exit 1
fi

# Extract instance ID from the result
INSTANCE_ID=$(echo "$INSTANCE_RESULT" | grep -o '"Id": "[^"]*' | cut -d'"' -f4)
INSTANCE_ARN=$(echo "$INSTANCE_RESULT" | grep -o '"Arn": "[^"]*' | cut -d'"' -f4)

if [[ -z "$INSTANCE_ID" ]]; then
    echo "ERROR: Failed to extract instance ID from the result" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Successfully created Amazon Connect instance with ID: $INSTANCE_ID" | tee -a "$LOG_FILE"
echo "Instance ARN: $INSTANCE_ARN" | tee -a "$LOG_FILE"

# Wait for the instance to be fully created and active
if ! wait_for_instance "$INSTANCE_ID"; then
    echo "ERROR: Instance did not become fully active within the timeout period" | tee -a "$LOG_FILE"
    cleanup_on_error
    exit 1
fi

# Step 2: Get security profiles to find the Admin profile ID
echo "Step 2: Getting security profiles..." | tee -a "$LOG_FILE"
SECURITY_PROFILES=$(log_cmd "aws connect list-security-profiles --instance-id $INSTANCE_ID --region $AWS_REGION --output json")

if ! check_error "$SECURITY_PROFILES" $? "Failed to list security profiles"; then
    cleanup_on_error
    exit 1
fi

# Save security profiles to a temporary file for easier processing
TEMP_FILE=$(mktemp)
echo "$SECURITY_PROFILES" > "$TEMP_FILE"

# Extract Admin security profile ID using grep and awk
ADMIN_PROFILE_ID=""
while IFS= read -r line; do
    if [[ "$line" =~ \"Name\":\ \"Admin\" ]]; then
        # Found the Admin profile, now get the ID from previous lines
        ADMIN_PROFILE_ID=$(grep -B 2 "$line" "$TEMP_FILE" | grep -o '"Id": "[^"]*' | head -1 | cut -d'"' -f4)
        break
    fi
done < "$TEMP_FILE"

# Clean up
rm -f "$TEMP_FILE"

if [[ -z "$ADMIN_PROFILE_ID" ]]; then
    echo "ERROR: Failed to find Admin security profile ID" | tee -a "$LOG_FILE"
    echo "Available security profiles:" | tee -a "$LOG_FILE"
    echo "$SECURITY_PROFILES" | tee -a "$LOG_FILE"
    cleanup_on_error
    exit 1
fi

echo "Found Admin security profile ID: $ADMIN_PROFILE_ID" | tee -a "$LOG_FILE"

# Step 3: Get routing profiles to find a default routing profile ID
echo "Step 3: Getting routing profiles..." | tee -a "$LOG_FILE"
ROUTING_PROFILES=$(log_cmd "aws connect list-routing-profiles --instance-id $INSTANCE_ID --region $AWS_REGION --output json")

if ! check_error "$ROUTING_PROFILES" $? "Failed to list routing profiles"; then
    cleanup_on_error
    exit 1
fi

# Extract the first routing profile ID
ROUTING_PROFILE_ID=$(echo "$ROUTING_PROFILES" | grep -o '"Id": "[^"]*' | head -1 | cut -d'"' -f4)

if [[ -z "$ROUTING_PROFILE_ID" ]]; then
    echo "ERROR: Failed to find a routing profile ID" | tee -a "$LOG_FILE"
    cleanup_on_error
    exit 1
fi

echo "Found routing profile ID: $ROUTING_PROFILE_ID" | tee -a "$LOG_FILE"

# Step 4: Create an admin user
echo "Step 4: Creating admin user..." | tee -a "$LOG_FILE"

# Generate a secure password
ADMIN_PASSWORD="Connect$(openssl rand -base64 12)"

USER_RESULT=$(log_cmd "aws connect create-user --instance-id $INSTANCE_ID --username admin --password \"$ADMIN_PASSWORD\" --identity-info FirstName=Admin,LastName=User,Email=admin@example.com --phone-config PhoneType=DESK_PHONE,AutoAccept=true,AfterContactWorkTimeLimit=30,DeskPhoneNumber=+12065550100 --security-profile-ids $ADMIN_PROFILE_ID --routing-profile-id $ROUTING_PROFILE_ID --region $AWS_REGION --output json")

if ! check_error "$USER_RESULT" $? "Failed to create admin user"; then
    cleanup_on_error
    exit 1
fi

# Extract user ID
USER_ID=$(echo "$USER_RESULT" | grep -o '"UserId": "[^"]*\|"Id": "[^"]*' | head -1 | cut -d'"' -f4)

if [[ -z "$USER_ID" ]]; then
    echo "ERROR: Failed to extract user ID from the result" | tee -a "$LOG_FILE"
    cleanup_on_error
    exit 1
fi

echo "Successfully created admin user with ID: $USER_ID" | tee -a "$LOG_FILE"
echo "Admin password: $ADMIN_PASSWORD" | tee -a "$LOG_FILE"

# Step 5: Configure telephony options
echo "Step 5: Configuring telephony options..." | tee -a "$LOG_FILE"

# Enable early media
EARLY_MEDIA_RESULT=$(log_cmd "aws connect update-instance-attribute --instance-id $INSTANCE_ID --attribute-type EARLY_MEDIA --value true --region $AWS_REGION")

if ! check_error "$EARLY_MEDIA_RESULT" $? "Failed to enable early media"; then
    cleanup_on_error
    exit 1
fi

# Enable multi-party calls and enhanced monitoring for voice
MULTI_PARTY_RESULT=$(log_cmd "aws connect update-instance-attribute --instance-id $INSTANCE_ID --attribute-type MULTI_PARTY_CONFERENCE --value true --region $AWS_REGION")

if ! check_error "$MULTI_PARTY_RESULT" $? "Failed to enable multi-party calls"; then
    cleanup_on_error
    exit 1
fi

# Enable multi-party chats and enhanced monitoring for chat
MULTI_PARTY_CHAT_RESULT=$(log_cmd "aws connect update-instance-attribute --instance-id $INSTANCE_ID --attribute-type MULTI_PARTY_CHAT_CONFERENCE --value true --region $AWS_REGION")

if ! check_error "$MULTI_PARTY_CHAT_RESULT" $? "Failed to enable multi-party chats"; then
    cleanup_on_error
    exit 1
fi

echo "Successfully configured telephony options" | tee -a "$LOG_FILE"

# Step 6: View storage configurations
echo "Step 6: Viewing storage configurations..." | tee -a "$LOG_FILE"

# List storage configurations for chat transcripts
STORAGE_CONFIGS=$(log_cmd "aws connect list-instance-storage-configs --instance-id $INSTANCE_ID --resource-type CHAT_TRANSCRIPTS --region $AWS_REGION --output json")

if ! check_error "$STORAGE_CONFIGS" $? "Failed to list storage configurations"; then
    cleanup_on_error
    exit 1
fi

echo "Successfully retrieved storage configurations" | tee -a "$LOG_FILE"

# Step 7: Verify instance details
echo "Step 7: Verifying instance details..." | tee -a "$LOG_FILE"
INSTANCE_DETAILS=$(log_cmd "aws connect describe-instance --instance-id $INSTANCE_ID --region $AWS_REGION --output json")

if ! check_error "$INSTANCE_DETAILS" $? "Failed to describe instance"; then
    cleanup_on_error
    exit 1
fi

echo "Successfully verified instance details" | tee -a "$LOG_FILE"

# Step 8: Search for available phone numbers (optional)
echo "Step 8: Searching for available phone numbers..." | tee -a "$LOG_FILE"
PHONE_NUMBERS=$(log_cmd "aws connect search-available-phone-numbers --target-arn $INSTANCE_ARN --phone-number-type TOLL_FREE --phone-number-country-code US --max-results 5 --region $AWS_REGION --output json")

if ! check_error "$PHONE_NUMBERS" $? "Failed to search for available phone numbers"; then
    cleanup_on_error
    exit 1
fi

# Extract the first phone number if available
PHONE_NUMBER=$(echo "$PHONE_NUMBERS" | grep -o '"PhoneNumber": "[^"]*' | head -1 | cut -d'"' -f4)

if [[ -n "$PHONE_NUMBER" ]]; then
    echo "Found available phone number: $PHONE_NUMBER" | tee -a "$LOG_FILE"
    
    # Ask if the user wants to claim the phone number
    echo ""
    echo "==========================================="
    echo "CLAIM PHONE NUMBER"
    echo "==========================================="
    echo "Do you want to claim the available phone number $PHONE_NUMBER? (y/n): "
    read -r CLAIM_CHOICE
    
    if [[ "$CLAIM_CHOICE" =~ ^[Yy] ]]; then
        echo "Claiming phone number..." | tee -a "$LOG_FILE"
        CLAIM_RESULT=$(log_cmd "aws connect claim-phone-number --target-arn $INSTANCE_ARN --phone-number $PHONE_NUMBER --region $AWS_REGION --output json")
        
        if ! check_error "$CLAIM_RESULT" $? "Failed to claim phone number"; then
            echo "WARNING: Failed to claim phone number, but continuing with script" | tee -a "$LOG_FILE"
        else
            echo "Successfully claimed phone number" | tee -a "$LOG_FILE"
            # Extract the phone number ID from the claim result
            PHONE_NUMBER_ID=$(echo "$CLAIM_RESULT" | grep -o '"PhoneNumberId": "[^"]*' | cut -d'"' -f4)
        fi
    else
        echo "Skipping phone number claim" | tee -a "$LOG_FILE"
    fi
else
    echo "No available phone numbers found" | tee -a "$LOG_FILE"
fi

# Display summary of created resources
echo ""
echo "==========================================="
echo "RESOURCE SUMMARY"
echo "==========================================="
echo "Amazon Connect Instance ID: $INSTANCE_ID"
echo "Amazon Connect Instance ARN: $INSTANCE_ARN"
echo "Admin User ID: $USER_ID"
echo "Admin Username: admin"
echo "Admin Password: $ADMIN_PASSWORD"
if [[ -n "$PHONE_NUMBER" && "$CLAIM_CHOICE" =~ ^[Yy] ]]; then
    echo "Claimed Phone Number: $PHONE_NUMBER"
    if [[ -n "$PHONE_NUMBER_ID" ]]; then
        echo "Claimed Phone Number ID: $PHONE_NUMBER_ID"
    fi
fi
echo "==========================================="
echo ""

# Ask if the user wants to clean up resources
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy] ]]; then
    echo "Starting cleanup..." | tee -a "$LOG_FILE"
    
    # Release claimed phone number if applicable
    if [[ -n "$PHONE_NUMBER_ID" && "$CLAIM_CHOICE" =~ ^[Yy] ]]; then
        echo "Releasing phone number: $PHONE_NUMBER_ID" | tee -a "$LOG_FILE"
        RELEASE_RESULT=$(log_cmd "aws connect release-phone-number --phone-number-id $PHONE_NUMBER_ID --region $AWS_REGION")
        
        if ! check_error "$RELEASE_RESULT" $? "Failed to release phone number"; then
            echo "WARNING: Failed to release phone number" | tee -a "$LOG_FILE"
        else
            echo "Successfully released phone number" | tee -a "$LOG_FILE"
        fi
        
        echo "Waiting for phone number release to complete..." | tee -a "$LOG_FILE"
        sleep 10
    fi
    
    # Delete the Amazon Connect instance (this will also delete all associated resources)
    echo "Deleting Amazon Connect instance: $INSTANCE_ID" | tee -a "$LOG_FILE"
    DELETE_RESULT=$(log_cmd "aws connect delete-instance --instance-id $INSTANCE_ID --region $AWS_REGION")
    
    if ! check_error "$DELETE_RESULT" $? "Failed to delete instance"; then
        echo "WARNING: Failed to delete instance" | tee -a "$LOG_FILE"
    else
        echo "Successfully deleted instance" | tee -a "$LOG_FILE"
    fi
    
    echo "Cleanup completed. All resources have been deleted." | tee -a "$LOG_FILE"
else
    echo "Cleanup skipped. Resources will remain in your AWS account." | tee -a "$LOG_FILE"
fi

echo "Script completed successfully. See $LOG_FILE for details." | tee -a "$LOG_FILE"
