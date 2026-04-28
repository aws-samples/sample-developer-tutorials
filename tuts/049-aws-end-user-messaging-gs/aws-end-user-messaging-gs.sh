#!/bin/bash

# AWS End User Messaging Push Getting Started Script
# This script creates an AWS End User Messaging Push application and demonstrates
# how to enable push notification channels and send a test message.
#
# Prerequisites:
# - AWS CLI installed and configured
# - Appropriate IAM permissions for Pinpoint operations
#
# Usage: ./2-cli-script-final-working.sh [--auto-cleanup]

set -euo pipefail

# Check for auto-cleanup flag
AUTO_CLEANUP=false
if [[ "${1:-}" == "--auto-cleanup" ]]; then
    AUTO_CLEANUP=true
fi

# Set up logging with secure permissions
LOG_FILE="aws-end-user-messaging-push-script-$(date +%Y%m%d-%H%M%S).log"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting AWS End User Messaging Push setup script..."
echo "Logging to $LOG_FILE"
echo "Timestamp: $(date)"

# Trap errors and cleanup
trap 'cleanup_on_error' ERR
trap 'cleanup_on_exit' EXIT

# Function to check for errors in command output
check_error() {
    local output=$1
    local cmd=$2
    local ignore_error=${3:-false}
    
    if echo "$output" | grep -qi "error\|exception\|fail"; then
        echo "ERROR: Command failed: $cmd" >&2
        echo "Error details: $output" >&2
        
        if [ "$ignore_error" = "true" ]; then
            echo "Ignoring error and continuing..." >&2
            return 1
        else
            return 2
        fi
    fi
    
    return 0
}

# Function to clean up resources on error
cleanup_on_error() {
    local exit_code=$?
    echo "Error encountered. Cleaning up resources..." >&2
    
    if [ -n "${APP_ID:-}" ] && [ ! -z "$APP_ID" ]; then
        echo "Attempting to delete application with ID: $APP_ID" >&2
        aws pinpoint delete-app --application-id "$APP_ID" 2>/dev/null || echo "Failed to delete application" >&2
    fi
    
    cleanup_files
    echo "Cleanup completed." >&2
    exit "$exit_code"
}

# Function to clean up files safely
cleanup_files() {
    local files=("gcm-message.json" "apns-message.json")
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            echo "Removed $file"
        fi
    done
}

# Function to clean up on normal exit
cleanup_on_exit() {
    :
}

# Function to validate AWS CLI is configured
validate_aws_cli() {
    echo "Validating AWS CLI configuration..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        echo "ERROR: AWS CLI is not installed. Please install it first." >&2
        echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" >&2
        exit 1
    fi
    
    # Check AWS CLI version
    AWS_VERSION=$(aws --version 2>&1 | head -n1)
    echo "AWS CLI version: $AWS_VERSION"
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "ERROR: AWS CLI is not configured or credentials are invalid." >&2
        echo "Please run 'aws configure' to set up your credentials." >&2
        exit 1
    fi
    
    # Get current AWS identity and region
    CALLER_IDENTITY=$(aws sts get-caller-identity --output json)
    CURRENT_REGION=$(aws configure get region 2>/dev/null || echo "us-east-1")
    echo "AWS CLI configured for:"
    echo "$CALLER_IDENTITY" | jq '.' 2>/dev/null || echo "$CALLER_IDENTITY"
    echo "Current region: $CURRENT_REGION"
    echo ""
}

# Function to check if jq is available for JSON parsing
check_json_tools() {
    if command -v jq &> /dev/null; then
        USE_JQ=true
        echo "jq is available for JSON parsing"
    else
        USE_JQ=false
        echo "jq is not available, using grep for JSON parsing" >&2
        echo "Consider installing jq for better JSON handling: https://stedolan.github.io/jq/" >&2
    fi
}

# Function to extract JSON values safely
extract_json_value() {
    local json=$1
    local key=$2
    
    if [ "$USE_JQ" = "true" ]; then
        echo "$json" | jq -r ".${key} // empty" 2>/dev/null || echo ""
    else
        # Fallback to grep method with proper escaping
        echo "$json" | grep -o "\"${key}\": \"[^\"]*" | cut -d'"' -f4 | head -n1 || echo ""
    fi
}

# Function to validate required IAM permissions
validate_permissions() {
    echo "Validating IAM permissions..."
    
    # Test basic Pinpoint permissions
    if ! aws pinpoint get-apps &> /dev/null; then
        echo "WARNING: Unable to list Pinpoint applications. Please ensure you have the following IAM permissions:" >&2
        echo "- mobiletargeting:GetApps" >&2
        echo "- mobiletargeting:CreateApp" >&2
        echo "- mobiletargeting:DeleteApp" >&2
        echo "- mobiletargeting:UpdateGcmChannel" >&2
        echo "- mobiletargeting:UpdateApnsChannel" >&2
        echo "- mobiletargeting:SendMessages" >&2
        echo "- mobiletargeting:TagResource" >&2
        echo "" >&2
        echo "Continuing anyway..." >&2
    else
        echo "Basic Pinpoint permissions validated."
    fi
}

# Function to securely generate random suffix
generate_random_suffix() {
    LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 8 | head -n1
}

# Function to validate resource names
validate_resource_name() {
    local name=$1
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Invalid resource name: $name" >&2
        return 1
    fi
    return 0
}

# Validate prerequisites
validate_aws_cli
check_json_tools
validate_permissions

# Generate a random suffix for resource names to avoid conflicts
RANDOM_SUFFIX=$(generate_random_suffix)
APP_NAME="PushNotificationApp-${RANDOM_SUFFIX}"

if ! validate_resource_name "$APP_NAME"; then
    echo "ERROR: Generated invalid app name" >&2
    exit 1
fi

echo "Creating application with name: $APP_NAME"

# Step 1: Create an application
echo "Executing: aws pinpoint create-app --create-application-request Name=${APP_NAME}"
CREATE_APP_OUTPUT=$(aws pinpoint create-app --create-application-request "Name=${APP_NAME}" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo "ERROR: Failed to create application" >&2
    echo "$CREATE_APP_OUTPUT" >&2
    exit 1
fi

check_error "$CREATE_APP_OUTPUT" "create-app" || exit 1

echo "Application created successfully:"
echo "$CREATE_APP_OUTPUT"

# Extract the application ID from the output
if [ "$USE_JQ" = "true" ]; then
    APP_ID=$(echo "$CREATE_APP_OUTPUT" | jq -r '.ApplicationResponse.Id // empty')
else
    APP_ID=$(echo "$CREATE_APP_OUTPUT" | grep -o '"Id": "[^"]*' | cut -d'"' -f4 | head -n1)
fi

if [ -z "$APP_ID" ] || [ "$APP_ID" = "null" ]; then
    echo "ERROR: Failed to extract application ID from output" >&2
    echo "Output was: $CREATE_APP_OUTPUT" >&2
    exit 1
fi

echo "Application ID: $APP_ID"

# Validate extracted APP_ID
if ! validate_resource_name "$APP_ID"; then
    echo "ERROR: Invalid application ID extracted" >&2
    exit 1
fi

# Tag the Pinpoint application after creation
echo "Tagging application: $APP_ID"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="${CURRENT_REGION}"
APP_ARN="arn:aws:mobiletargeting:${REGION}:${ACCOUNT_ID}:app/${APP_ID}"

# Validate ARN format
if [[ ! "$APP_ARN" =~ ^arn:aws:mobiletargeting:[a-z0-9-]+:[0-9]{12}:app/[a-zA-Z0-9-]+$ ]]; then
    echo "ERROR: Invalid ARN format: $APP_ARN" >&2
    exit 1
fi

TAG_OUTPUT=$(aws pinpoint tag-resource --resource-arn "$APP_ARN" --tags-model Key=project,Value=doc-smith Key=tutorial,Value=aws-end-user-messaging-gs 2>&1)
if check_error "$TAG_OUTPUT" "tag-resource for Pinpoint app" "true"; then
    echo "Application tagged successfully."
fi

# Create a resources list to track what we've created
RESOURCES=("Application: $APP_ID")

# Step 2: Enable FCM (GCM) channel with a sample API key
echo ""
echo "==========================================="
echo "ENABLING FCM (GCM) CHANNEL"
echo "==========================================="
echo "Note: This is using a placeholder API key for demonstration purposes only."
echo "In a production environment, you should use your actual FCM API key from Firebase Console."
echo ""
echo "IMPORTANT: The following command will likely fail because we're using a placeholder API key."
echo "This is expected behavior for this demonstration script."

echo "Executing: aws pinpoint update-gcm-channel --application-id $APP_ID --gcm-channel-request ..."
UPDATE_GCM_OUTPUT=$(aws pinpoint update-gcm-channel \
    --application-id "$APP_ID" \
    --gcm-channel-request '{"Enabled": true, "ApiKey": "sample-fcm-api-key-for-demo-only"}' 2>&1)

if check_error "$UPDATE_GCM_OUTPUT" "update-gcm-channel" "true"; then
    echo "FCM channel enabled successfully:"
    echo "$UPDATE_GCM_OUTPUT"
    RESOURCES+=("GCM Channel for application: $APP_ID")
else
    echo "As expected, FCM channel update failed with the placeholder API key." >&2
    echo "Error details: $UPDATE_GCM_OUTPUT" >&2
    echo ""
    echo "To enable FCM in production:"
    echo "1. Go to Firebase Console (https://console.firebase.google.com/)"
    echo "2. Create or select your project"
    echo "3. Go to Project Settings > Cloud Messaging"
    echo "4. Copy the Server Key"
    echo "5. Replace 'sample-fcm-api-key-for-demo-only' with your actual Server Key"
fi

# Step 3: Try to enable APNS channel (this will also fail without real certificates)
echo ""
echo "==========================================="
echo "ENABLING APNS CHANNEL (OPTIONAL)"
echo "==========================================="
echo "Attempting to enable APNS channel with placeholder certificate..."
echo "This will also fail without real APNS certificates, which is expected."

echo "Executing: aws pinpoint update-apns-channel --application-id $APP_ID --apns-channel-request ..."
UPDATE_APNS_OUTPUT=$(aws pinpoint update-apns-channel \
    --application-id "$APP_ID" \
    --apns-channel-request '{"Enabled": true, "Certificate": "placeholder-certificate", "PrivateKey": "placeholder-private-key"}' 2>&1)

if check_error "$UPDATE_APNS_OUTPUT" "update-apns-channel" "true"; then
    echo "APNS channel enabled successfully:"
    echo "$UPDATE_APNS_OUTPUT"
    RESOURCES+=("APNS Channel for application: $APP_ID")
else
    echo "As expected, APNS channel update failed with placeholder certificates." >&2
    echo "Error details: $UPDATE_APNS_OUTPUT" >&2
    echo ""
    echo "To enable APNS in production:"
    echo "1. Generate APNS certificates from Apple Developer Console"
    echo "2. Convert certificates to PEM format"
    echo "3. Use the actual certificate and private key in the update-apns-channel command"
fi

# Step 4: Create message files for different platforms
echo ""
echo "==========================================="
echo "CREATING MESSAGE FILES"
echo "==========================================="

# Create FCM message file with restricted permissions
echo "Creating FCM message file..."
cat > gcm-message.json << 'EOF'
{
  "Addresses": {
    "SAMPLE-DEVICE-TOKEN-FCM": {
      "ChannelType": "GCM"
    }
  },
  "MessageConfiguration": {
    "GCMMessage": {
      "Action": "OPEN_APP",
      "Body": "Hello from AWS End User Messaging Push! This is an FCM notification.",
      "Priority": "normal",
      "SilentPush": false,
      "Title": "My First FCM Push Notification",
      "TimeToLive": 30,
      "Data": {
        "key1": "value1",
        "key2": "value2"
      }
    }
  }
}
EOF
chmod 600 gcm-message.json

# Create APNS message file with restricted permissions
echo "Creating APNS message file..."
cat > apns-message.json << 'EOF'
{
  "Addresses": {
    "SAMPLE-DEVICE-TOKEN-APNS": {
      "ChannelType": "APNS"
    }
  },
  "MessageConfiguration": {
    "APNSMessage": {
      "Action": "OPEN_APP",
      "Body": "Hello from AWS End User Messaging Push! This is an APNS notification.",
      "Priority": "normal",
      "SilentPush": false,
      "Title": "My First APNS Push Notification",
      "TimeToLive": 30,
      "Badge": 1,
      "Sound": "default"
    }
  }
}
EOF
chmod 600 apns-message.json

echo "Message files created:"
echo "- gcm-message.json (for FCM/Android)"
echo "- apns-message.json (for APNS/iOS)"
echo ""
echo "Note: These messages use placeholder device tokens and will not actually be delivered."
echo "To send real messages, you would need to replace the sample device tokens with actual ones."

# Step 5: Demonstrate how to send messages (this will fail with placeholder tokens)
echo ""
echo "==========================================="
echo "DEMONSTRATING MESSAGE SENDING"
echo "==========================================="
echo "Attempting to send FCM message (will fail with placeholder token)..."

echo "Executing: aws pinpoint send-messages --application-id $APP_ID --message-request file://gcm-message.json"
SEND_FCM_OUTPUT=$(aws pinpoint send-messages \
    --application-id "$APP_ID" \
    --message-request file://gcm-message.json 2>&1)

if check_error "$SEND_FCM_OUTPUT" "send-messages (FCM)" "true"; then
    echo "FCM message sent successfully:"
    echo "$SEND_FCM_OUTPUT"
else
    echo "As expected, FCM message sending failed with placeholder token." >&2
    echo "Error details: $SEND_FCM_OUTPUT" >&2
fi

echo ""
echo "Attempting to send APNS message (will fail with placeholder token)..."

echo "Executing: aws pinpoint send-messages --application-id $APP_ID --message-request file://apns-message.json"
SEND_APNS_OUTPUT=$(aws pinpoint send-messages \
    --application-id "$APP_ID" \
    --message-request file://apns-message.json 2>&1)

if check_error "$SEND_APNS_OUTPUT" "send-messages (APNS)" "true"; then
    echo "APNS message sent successfully:"
    echo "$SEND_APNS_OUTPUT"
else
    echo "As expected, APNS message sending failed with placeholder token." >&2
    echo "Error details: $SEND_APNS_OUTPUT" >&2
fi

# Step 6: Show application details
echo ""
echo "==========================================="
echo "APPLICATION DETAILS"
echo "==========================================="
echo "Retrieving application details..."

echo "Executing: aws pinpoint get-app --application-id $APP_ID"
GET_APP_OUTPUT=$(aws pinpoint get-app --application-id "$APP_ID" 2>&1)
if check_error "$GET_APP_OUTPUT" "get-app"; then
    echo "Application details:"
    echo "$GET_APP_OUTPUT"
fi

# Display summary of created resources
echo ""
echo "==========================================="
echo "RESOURCES CREATED"
echo "==========================================="
for resource in "${RESOURCES[@]}"; do
    echo "- $resource"
done

echo ""
echo "Files created:"
echo "- gcm-message.json"
echo "- apns-message.json"
echo "- $LOG_FILE"

# Cleanup prompt with proper input handling
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "This script created AWS resources that may incur charges."

if [ "$AUTO_CLEANUP" = "true" ]; then
    echo "Auto-cleanup enabled. Cleaning up resources..."
    CLEANUP_CHOICE="y"
else
    echo "Do you want to clean up all created resources? (y/n): "
    read -r -t 300 CLEANUP_CHOICE
    CLEANUP_CHOICE="${CLEANUP_CHOICE:-n}"
fi

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Cleaning up resources..."
    
    if [ -n "${APP_ID:-}" ] && [ ! -z "$APP_ID" ]; then
        echo "Deleting application with ID: $APP_ID"
        echo "Executing: aws pinpoint delete-app --application-id $APP_ID"
        DELETE_APP_OUTPUT=$(aws pinpoint delete-app --application-id "$APP_ID" 2>&1)
        if check_error "$DELETE_APP_OUTPUT" "delete-app" "true"; then
            echo "Application deleted successfully."
        else
            echo "Failed to delete application. You may need to delete it manually:" >&2
            echo "aws pinpoint delete-app --application-id $APP_ID" >&2
        fi
    fi
    
    echo "Deleting message files..."
    cleanup_files
    
    echo "Cleanup completed successfully."
    echo "Log file ($LOG_FILE) has been preserved for reference."
else
    echo ""
    echo "Skipping cleanup. Resources will remain in your AWS account."
    echo ""
    echo "To manually delete the application later, run:"
    echo "aws pinpoint delete-app --application-id $APP_ID"
    echo ""
    echo "To delete the message files, run:"
    echo "rm -f gcm-message.json apns-message.json"
fi

echo ""
echo "==========================================="
echo "SCRIPT COMPLETED SUCCESSFULLY"
echo "==========================================="
echo "This script demonstrated:"
echo "1. Creating an AWS End User Messaging Push application"
echo "2. Attempting to enable FCM and APNS channels (with placeholder credentials)"
echo "3. Creating message templates for different platforms"
echo "4. Demonstrating message sending commands (with placeholder tokens)"
echo "5. Retrieving application details"
echo "6. Proper cleanup of resources"
echo ""
echo "For production use:"
echo "- Replace placeholder API keys with real FCM server keys"
echo "- Replace placeholder certificates with real APNS certificates"
echo "- Replace placeholder device tokens with real device tokens"
echo "- Implement proper error handling for your use case"
echo "- Consider using AWS IAM roles instead of long-term credentials"
echo "- Use temporary credentials and rotate them regularly"
echo "- Enable MFA for your AWS account"
echo "- Use resource-based policies to restrict access"
echo "- Encrypt sensitive data at rest and in transit"
echo ""
echo "Log file: $LOG_FILE"
echo "Script completed at: $(date)"