#!/bin/bash

# AWS Payment Cryptography Getting Started Script
# This script demonstrates how to use AWS Payment Cryptography to create a key,
# generate and verify CVV2 values, and clean up resources.

# Initialize log file
LOG_FILE="payment-cryptography-tutorial.log"
echo "AWS Payment Cryptography Tutorial - $(date)" > $LOG_FILE

# Function to log messages
log() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" | tee -a $LOG_FILE
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
    
    if [ -n "$KEY_ARN" ]; then
        echo "Key ARN: $KEY_ARN"
    fi
    
    exit 1
}

# Function to check command output for errors
check_error() {
    local output="$1"
    local command="$2"
    
    if echo "$output" | grep -i "error\|exception\|fail" > /dev/null; then
        handle_error "Command failed: $command. Output: $output"
    fi
}

log "Starting AWS Payment Cryptography tutorial"

# Step 1: Create a key
log "Step 1: Creating a card verification key (CVK)"
KEY_OUTPUT=$(aws payment-cryptography create-key \
  --exportable \
  --key-attributes KeyAlgorithm=TDES_2KEY,KeyUsage=TR31_C0_CARD_VERIFICATION_KEY,KeyClass=SYMMETRIC_KEY,KeyModesOfUse='{Generate=true,Verify=true}' 2>&1)

echo "$KEY_OUTPUT"
check_error "$KEY_OUTPUT" "create-key"

# Extract the Key ARN from the output
KEY_ARN=$(echo "$KEY_OUTPUT" | grep -o '"KeyArn": "[^"]*' | cut -d'"' -f4)

if [ -z "$KEY_ARN" ]; then
    handle_error "Failed to extract Key ARN from output"
fi

log "Successfully created key with ARN: $KEY_ARN"

# Step 2: Generate a CVV2 value
log "Step 2: Generating a CVV2 value"
CVV2_OUTPUT=$(aws payment-cryptography-data generate-card-validation-data \
  --key-identifier "$KEY_ARN" \
  --primary-account-number=171234567890123 \
  --generation-attributes CardVerificationValue2={CardExpiryDate=0123} 2>&1)

echo "$CVV2_OUTPUT"
check_error "$CVV2_OUTPUT" "generate-card-validation-data"

# Extract the CVV2 value from the output - updated to use ValidationData instead of CardDataValue
CVV2_VALUE=$(echo "$CVV2_OUTPUT" | grep -o '"ValidationData": "[^"]*' | cut -d'"' -f4)

if [ -z "$CVV2_VALUE" ]; then
    handle_error "Failed to extract CVV2 value from output"
fi

log "Successfully generated CVV2 value: $CVV2_VALUE"

# Step 3: Verify the CVV2 value
log "Step 3: Verifying the CVV2 value"
VERIFY_OUTPUT=$(aws payment-cryptography-data verify-card-validation-data \
  --key-identifier "$KEY_ARN" \
  --primary-account-number=171234567890123 \
  --verification-attributes CardVerificationValue2={CardExpiryDate=0123} \
  --validation-data "$CVV2_VALUE" 2>&1)

echo "$VERIFY_OUTPUT"
check_error "$VERIFY_OUTPUT" "verify-card-validation-data"

log "Successfully verified CVV2 value"

# Step 4: Perform a negative test
log "Step 4: Performing a negative test with incorrect CVV2"
NEGATIVE_OUTPUT=$(aws payment-cryptography-data verify-card-validation-data \
  --key-identifier "$KEY_ARN" \
  --primary-account-number=171234567890123 \
  --verification-attributes CardVerificationValue2={CardExpiryDate=0123} \
  --validation-data 999 2>&1 || echo "Expected error: Verification failed")

echo "$NEGATIVE_OUTPUT"

if ! echo "$NEGATIVE_OUTPUT" | grep -i "fail\|error" > /dev/null; then
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
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    log "Step 5: Cleaning up resources"
    
    # Delete the key
    log "Deleting key: $KEY_ARN"
    DELETE_OUTPUT=$(aws payment-cryptography delete-key \
      --key-identifier "$KEY_ARN" 2>&1)
    
    echo "$DELETE_OUTPUT"
    check_error "$DELETE_OUTPUT" "delete-key"
    
    log "Key scheduled for deletion. Default waiting period is 7 days."
    log "To cancel deletion before the waiting period ends, use:"
    log "aws payment-cryptography restore-key --key-identifier $KEY_ARN"
    
    echo ""
    echo "==========================================="
    echo "CLEANUP COMPLETE"
    echo "==========================================="
    echo "The key has been scheduled for deletion after the default waiting period (7 days)."
    echo "To cancel deletion before the waiting period ends, use:"
    echo "aws payment-cryptography restore-key --key-identifier $KEY_ARN"
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
