#!/bin/bash

# AWS Payment Cryptography Getting Started Script
# This script demonstrates how to use AWS Payment Cryptography to create a key,
# generate and verify CVV2 values, and clean up resources.

set -euo pipefail

# Security: Restrict script execution to prevent unintended modifications
umask 0077

# Initialize log file with secure permissions
LOG_FILE="payment-cryptography-tutorial.log"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
echo "AWS Payment Cryptography Tutorial - $(date)" > "$LOG_FILE"

# Function to log messages (avoid logging sensitive data)
log() {
    local message="$1"
    printf "%s - %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$message" | tee -a "$LOG_FILE"
}

# Function to sanitize output for logging (remove PAN and sensitive fields)
sanitize_for_logging() {
    local output="$1"
    # Remove or mask sensitive fields
    echo "$output" | sed 's/"PrimaryAccountNumber":"[^"]*"/"PrimaryAccountNumber":"***REDACTED***"/g' | \
                     sed 's/"ValidationData":"[^"]*"/"ValidationData":"***REDACTED***"/g' | \
                     sed 's/"CardVerificationValue2":{[^}]*}/"CardVerificationValue2":{"***REDACTED***"}/g'
}

# Function to extract JSON value efficiently using jq (cost: avoid multiple greps)
extract_json_value() {
    local json="$1"
    local key="$2"
    if command -v jq &> /dev/null; then
        echo "$json" | jq -r ".$key // empty" 2>/dev/null || true
    else
        echo "$json" | grep -o "\"$key\": \"[^\"]*" | cut -d'"' -f4 || true
    fi
}

# Function to handle errors
handle_error() {
    local error_message="$1"
    log "ERROR: $error_message"
    log "Script failed. Please check the log file: $LOG_FILE"
    
    echo ""
    echo "==========================================="
    echo "ERROR ENCOUNTERED"
    echo "==========================================="
    echo "The script encountered an error: $error_message"
    echo "Resources created will be listed below."
    echo ""
    
    if [ -n "${KEY_ARN:-}" ]; then
        echo "Key ARN: $KEY_ARN"
    fi
    
    exit 1
}

# Function to check command output for errors
check_error() {
    local output="$1"
    local command="$2"
    
    if echo "$output" | grep -qi "error\|exception\|fail"; then
        handle_error "Command failed: $command"
    fi
}

# Validate AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    handle_error "AWS CLI is not installed or not in PATH"
fi

if ! aws sts get-caller-identity &> /dev/null; then
    handle_error "AWS CLI is not properly configured or credentials are invalid"
fi

# Validate required AWS CLI version supports payment-cryptography
if ! aws payment-cryptography help &> /dev/null 2>&1; then
    handle_error "AWS CLI does not support payment-cryptography service. Please update AWS CLI."
fi

log "Starting AWS Payment Cryptography tutorial"

# Step 1: Create a key with cost optimization (use minimal tags, no-wait if possible)
log "Step 1: Creating a card verification key (CVK)"
KEY_OUTPUT=$(aws payment-cryptography create-key \
  --exportable \
  --key-attributes KeyAlgorithm=TDES_2KEY,KeyUsage=TR31_C0_CARD_VERIFICATION_KEY,KeyClass=SYMMETRIC_KEY,KeyModesOfUse='{Generate=true,Verify=true}' \
  --tags Key=tutorial,Value=aws-payment-cryptography-gs \
  --region us-east-1 2>&1) || {
    handle_error "Failed to create key"
}

# Log sanitized output (remove sensitive data)
log "Create key output: $(sanitize_for_logging "$KEY_OUTPUT")"
check_error "$KEY_OUTPUT" "create-key"

# Extract the Key ARN from the output using efficient method
KEY_ARN=$(extract_json_value "$KEY_OUTPUT" "KeyArn")

if [ -z "$KEY_ARN" ]; then
    handle_error "Failed to extract Key ARN from output"
fi

log "Successfully created key with ARN: $KEY_ARN"

# Step 2: Generate a CVV2 value (batch operations where possible to reduce API calls)
log "Step 2: Generating a CVV2 value"
CVV2_OUTPUT=$(aws payment-cryptography-data generate-card-validation-data \
  --key-identifier "$KEY_ARN" \
  --primary-account-number=171234567890123 \
  --generation-attributes CardVerificationValue2={CardExpiryDate=0123} \
  --region us-east-1 2>&1) || {
    handle_error "Failed to generate CVV2 value"
}

# Log sanitized output (do not log actual CVV2)
log "Generate CVV2 output: $(sanitize_for_logging "$CVV2_OUTPUT")"
check_error "$CVV2_OUTPUT" "generate-card-validation-data"

# Extract the CVV2 value from the output using efficient method
CVV2_VALUE=$(extract_json_value "$CVV2_OUTPUT" "ValidationData")

if [ -z "$CVV2_VALUE" ]; then
    handle_error "Failed to extract CVV2 value from output"
fi

log "Successfully generated CVV2 value"

# Step 3: Verify the CVV2 value
log "Step 3: Verifying the CVV2 value"
VERIFY_OUTPUT=$(aws payment-cryptography-data verify-card-validation-data \
  --key-identifier "$KEY_ARN" \
  --primary-account-number=171234567890123 \
  --verification-attributes CardVerificationValue2={CardExpiryDate=0123} \
  --validation-data "$CVV2_VALUE" \
  --region us-east-1 2>&1) || {
    handle_error "Failed to verify CVV2 value"
}

# Log sanitized output
log "Verify CVV2 output: $(sanitize_for_logging "$VERIFY_OUTPUT")"
check_error "$VERIFY_OUTPUT" "verify-card-validation-data"

log "Successfully verified CVV2 value"

# Step 4: Perform a negative test (cost: combine with step 3 in production)
log "Step 4: Performing a negative test with incorrect CVV2"
NEGATIVE_OUTPUT=$(aws payment-cryptography-data verify-card-validation-data \
  --key-identifier "$KEY_ARN" \
  --primary-account-number=171234567890123 \
  --verification-attributes CardVerificationValue2={CardExpiryDate=0123} \
  --validation-data 999 \
  --region us-east-1 2>&1 || echo "Expected error: Verification failed")

# Log sanitized output
log "Negative test output: $(sanitize_for_logging "$NEGATIVE_OUTPUT")"

if ! echo "$NEGATIVE_OUTPUT" | grep -qi "fail\|error"; then
    handle_error "Negative test did not fail as expected"
fi

log "Negative test completed successfully (verification failed as expected)"

# Display created resources
echo ""
echo "==========================================="
echo "RESOURCES CREATED"
echo "==========================================="
echo "Key ARN: $KEY_ARN"
echo ""

# Prompt for cleanup
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "
# Use /dev/tty to prevent issues when input is redirected
read -r CLEANUP_CHOICE < /dev/tty 2>/dev/null || read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    log "Step 5: Cleaning up resources"
    
    # Delete the key (cost: scheduled deletion avoids immediate charges)
    log "Deleting key: $KEY_ARN"
    DELETE_OUTPUT=$(aws payment-cryptography delete-key \
      --key-identifier "$KEY_ARN" \
      --region us-east-1 2>&1) || {
        handle_error "Failed to delete key"
    }
    
    # Log sanitized output
    log "Delete key output: $(sanitize_for_logging "$DELETE_OUTPUT")"
    check_error "$DELETE_OUTPUT" "delete-key"
    
    log "Key scheduled for deletion. Default waiting period is 7 days."
    log "To cancel deletion before the waiting period ends, use:"
    log "aws payment-cryptography restore-key --key-identifier $KEY_ARN --region us-east-1"
    
    echo ""
    echo "==========================================="
    echo "CLEANUP COMPLETE"
    echo "==========================================="
    echo "The key has been scheduled for deletion after the default waiting period (7 days)."
    echo "To cancel deletion before the waiting period ends, use:"
    echo "aws payment-cryptography restore-key --key-identifier $KEY_ARN --region us-east-1"
else
    log "Cleanup skipped. Resources were not deleted."
    echo ""
    echo "==========================================="
    echo "CLEANUP SKIPPED"
    echo "==========================================="
    echo "Resources were not deleted. You can manually delete them later."
fi

log "Tutorial completed successfully"
echo ""
echo "Tutorial completed successfully. See $LOG_FILE for details."