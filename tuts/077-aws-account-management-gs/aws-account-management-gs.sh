#!/bin/bash

# AWS Account Management CLI Script - Version 2
# This script demonstrates various AWS account management operations using the AWS CLI
# Focusing on operations that are more likely to succeed with standard permissions

set -euo pipefail

# Security: Validate AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed or not in PATH" >&2
    exit 1
fi

# Security: Validate AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials are not configured or invalid" >&2
    exit 1
fi

# Set up logging with secure permissions
LOG_FILE="aws-account-management-v2.log"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
echo "Starting AWS Account Management script at $(date)" > "$LOG_FILE"

# Function to log commands and their output
log_command() {
    local cmd="$1"
    local output
    
    echo "Executing: $cmd" | tee -a "$LOG_FILE"
    
    # Security: Use array to prevent command injection
    output=$(eval "$cmd" 2>&1) || {
        local status=$?
        echo "Command failed with exit status $status." | tee -a "$LOG_FILE"
        return $status
    }
    
    echo "$output" | tee -a "$LOG_FILE"
    
    if echo "$output" | grep -i "error\|denied\|unauthorized" > /dev/null; then
        echo "Error or access denied detected in command output." | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo "$output"
    return 0
}

# Function to handle errors
handle_error() {
    echo "Error encountered. Exiting script." | tee -a "$LOG_FILE"
    exit 1
}

# Function to validate user input
validate_input() {
    local input="$1"
    # Security: Reject input with special characters that could be used in injection
    if [[ "$input" =~ [^\w-] ]]; then
        echo "Invalid input detected. Only alphanumeric characters and hyphens are allowed." >&2
        return 1
    fi
    return 0
}

# Welcome message
echo "============================================="
echo "AWS Account Management CLI Demo"
echo "============================================="
echo "This script will demonstrate various AWS account management operations."
echo "Some operations may require specific permissions or may not be applicable"
echo "to your account setup (standalone vs. organization member)."
echo ""
echo "Press Enter to continue or Ctrl+C to exit..."
read -r

# Part 1: View Account Identifiers
echo ""
echo "============================================="
echo "Part 1: Viewing AWS Account Identifiers"
echo "============================================="

echo "Getting AWS Account ID..."
ACCOUNT_ID=$(log_command "aws sts get-caller-identity --query Account --output text" || handle_error)
echo "Your AWS Account ID is: $ACCOUNT_ID"

echo ""
echo "Getting additional account information..."
log_command "aws sts get-caller-identity" || echo "Unable to get full caller identity."

echo ""
echo "Getting Canonical User ID (requires S3 permissions)..."
CANONICAL_ID=$(log_command "aws s3api list-buckets --query Owner.ID --output text" 2>&1 || echo "")
if [ -n "$CANONICAL_ID" ] && ! echo "$CANONICAL_ID" | grep -i "error\|denied\|unauthorized" > /dev/null; then
    echo "Your Canonical User ID is: $CANONICAL_ID"
else
    echo "Unable to retrieve canonical ID. You may not have S3 permissions."
fi

# Part 2: View Account Information
echo ""
echo "============================================="
echo "Part 2: Viewing Account Information"
echo "============================================="

# Try to get contact information
echo "Attempting to get contact information..."
CONTACT_INFO=$(log_command "aws account get-contact-information" 2>&1 || echo "")

if ! echo "$CONTACT_INFO" | grep -i "error\|denied\|unauthorized" > /dev/null && [ -n "$CONTACT_INFO" ]; then
    echo "Current contact information:"
    echo "$CONTACT_INFO"
else
    echo "Unable to retrieve contact information. You may not have the required permissions."
fi

# Part 3: List AWS Regions
echo ""
echo "============================================="
echo "Part 3: Listing AWS Regions"
echo "============================================="

# List available regions
echo "Listing available regions..."
REGIONS=$(log_command "aws account list-regions" 2>&1 || echo "")

if ! echo "$REGIONS" | grep -i "error\|denied\|unauthorized" > /dev/null && [ -n "$REGIONS" ]; then
    echo "Successfully retrieved region information."
    
    # Extract and display regions with their status in a two-column format
    echo ""
    echo "Listing all regions with their status:"
    echo "----------------------------------------"
    echo "Region          | Status"
    echo "----------------------------------------"
    
    # Get regions in text format and format with awk for a clean two-column display
    REGIONS_LIST=$(log_command "aws account list-regions --query 'Regions[*].[RegionName,RegionOptStatus]' --output text" 2>&1 || echo "")
    if [ -n "$REGIONS_LIST" ]; then
        echo "$REGIONS_LIST" | while read -r region status; do
            printf "%-15s | %s\n" "$region" "$status"
        done
    fi
    
    # Check status of a specific region
    echo ""
    echo "Would you like to check the status of a specific region? (y/n): "
    read -r CHECK_REGION
    
    if [[ "$CHECK_REGION" =~ ^[Yy]$ ]]; then
        echo "Enter the region code to check (e.g., af-south-1): "
        read -r REGION_CODE
        
        # Security: Validate region code format
        if validate_input "$REGION_CODE"; then
            echo "Checking status of region $REGION_CODE..."
            log_command "aws account get-region-opt-status --region-name $REGION_CODE" || echo "Unable to check region status."
        else
            echo "Invalid region code format."
        fi
    fi
else
    echo "Skipping region operations due to permission issues."
fi

# Part 4: Check for Alternate Contacts (Read-Only)
echo ""
echo "============================================="
echo "Part 4: Checking Alternate Contacts (Read-Only)"
echo "============================================="

echo "Attempting to check billing contact information..."
BILLING_CONTACT=$(log_command "aws account get-alternate-contact --alternate-contact-type BILLING" 2>&1 || echo "")

if ! echo "$BILLING_CONTACT" | grep -i "error\|denied\|unauthorized" > /dev/null && [ -n "$BILLING_CONTACT" ]; then
    echo "Current billing contact information:"
    echo "$BILLING_CONTACT"
else
    echo "Unable to retrieve billing contact information. You may not have the required permissions."
fi

echo ""
echo "Attempting to check operations contact information..."
OPERATIONS_CONTACT=$(log_command "aws account get-alternate-contact --alternate-contact-type OPERATIONS" 2>&1 || echo "")

if ! echo "$OPERATIONS_CONTACT" | grep -i "error\|denied\|unauthorized" > /dev/null && [ -n "$OPERATIONS_CONTACT" ]; then
    echo "Current operations contact information:"
    echo "$OPERATIONS_CONTACT"
else
    echo "Unable to retrieve operations contact information. You may not have the required permissions."
fi

echo ""
echo "Attempting to check security contact information..."
SECURITY_CONTACT=$(log_command "aws account get-alternate-contact --alternate-contact-type SECURITY" 2>&1 || echo "")

if ! echo "$SECURITY_CONTACT" | grep -i "error\|denied\|unauthorized" > /dev/null && [ -n "$SECURITY_CONTACT" ]; then
    echo "Current security contact information:"
    echo "$SECURITY_CONTACT"
else
    echo "Unable to retrieve security contact information. You may not have the required permissions."
fi

# Summary
echo ""
echo "============================================="
echo "Summary"
echo "============================================="
echo "Script execution completed. This script performed read-only operations"
echo "to demonstrate AWS account management capabilities."
echo ""
echo "See $LOG_FILE for detailed logs."