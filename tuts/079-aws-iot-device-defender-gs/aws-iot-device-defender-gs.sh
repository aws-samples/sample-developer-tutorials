#!/bin/bash

# AWS IoT Device Defender Getting Started Script
# This script demonstrates how to use AWS IoT Device Defender to enable audit checks,
# view audit results, create mitigation actions, and apply them to findings.

# Set up logging
LOG_FILE="iot-device-defender-script-$(date +%Y%m%d%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==================================================="
echo "AWS IoT Device Defender Getting Started Script"
echo "==================================================="
echo "Starting script execution at $(date)"
echo ""

# Function to check for errors in command output
check_error() {
    if echo "$1" | grep -i "An error occurred\|Exception\|Failed\|usage: aws" > /dev/null; then
        echo "ERROR: Command failed with the following output:"
        echo "$1"
        return 1
    fi
    return 0
}

# Function to create IAM roles
create_iam_role() {
    local ROLE_NAME=$1
    local TRUST_POLICY=$2
    local MANAGED_POLICY=$3
    
    echo "Creating IAM role: $ROLE_NAME"
    
    # Check if role already exists
    ROLE_EXISTS=$(aws iam get-role --role-name "$ROLE_NAME" 2>&1 || echo "NOT_EXISTS")
    
    if echo "$ROLE_EXISTS" | grep -i "NoSuchEntity" > /dev/null; then
        # Create the role with trust policy
        ROLE_RESULT=$(aws iam create-role \
            --role-name "$ROLE_NAME" \
            --assume-role-policy-document "$TRUST_POLICY" 2>&1)
        
        if ! check_error "$ROLE_RESULT"; then
            echo "Failed to create role $ROLE_NAME"
            return 1
        fi
        
        # For IoT logging role, create an inline policy instead of using a managed policy
        if [[ "$ROLE_NAME" == "AWSIoTLoggingRole" ]]; then
            LOGGING_POLICY='{
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": [
                            "logs:CreateLogGroup",
                            "logs:CreateLogStream",
                            "logs:PutLogEvents",
                            "logs:PutMetricFilter",
                            "logs:PutRetentionPolicy",
                            "logs:GetLogEvents",
                            "logs:DescribeLogStreams"
                        ],
                        "Resource": [
                            "arn:aws:logs:*:*:*"
                        ]
                    }
                ]
            }'
            
            POLICY_RESULT=$(aws iam put-role-policy \
                --role-name "$ROLE_NAME" \
                --policy-name "${ROLE_NAME}Policy" \
                --policy-document "$LOGGING_POLICY" 2>&1)
                
            if ! check_error "$POLICY_RESULT"; then
                echo "Failed to attach inline policy to role $ROLE_NAME"
                return 1
            fi
        elif [[ "$ROLE_NAME" == "IoTMitigationActionErrorLoggingRole" ]]; then
            MITIGATION_POLICY='{
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": [
                            "iot:UpdateCACertificate",
                            "iot:UpdateCertificate",
                            "iot:SetV2LoggingOptions",
                            "iot:SetLoggingOptions",
                            "iot:AddThingToThingGroup",
                            "iot:PublishToTopic",
                            "iam:PassRole"
                        ],
                        "Resource": "*"
                    }
                ]
            }'
            
            POLICY_RESULT=$(aws iam put-role-policy \
                --role-name "$ROLE_NAME" \
                --policy-name "${ROLE_NAME}Policy" \
                --policy-document "$MITIGATION_POLICY" 2>&1)
                
            if ! check_error "$POLICY_RESULT"; then
                echo "Failed to attach inline policy to role $ROLE_NAME"
                return 1
            fi
        else
            # Attach managed policy to role if provided
            if [ -n "$MANAGED_POLICY" ]; then
                ATTACH_RESULT=$(aws iam attach-role-policy \
                    --role-name "$ROLE_NAME" \
                    --policy-arn "$MANAGED_POLICY" 2>&1)
                
                if ! check_error "$ATTACH_RESULT"; then
                    echo "Failed to attach policy to role $ROLE_NAME"
                    return 1
                fi
            fi
        fi
        
        echo "Role $ROLE_NAME created successfully"
    else
        echo "Role $ROLE_NAME already exists, skipping creation"
    fi
    
    # Get the role ARN
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
    echo "Role ARN: $ROLE_ARN"
    return 0
}

# Array to store created resources for cleanup
declare -a CREATED_RESOURCES

# Step 1: Create IAM roles needed for the tutorial
echo "==================================================="
echo "Step 1: Creating required IAM roles"
echo "==================================================="

# Create IoT Device Defender Audit role
IOT_DEFENDER_AUDIT_TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "iot.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'

create_iam_role "AWSIoTDeviceDefenderAuditRole" "$IOT_DEFENDER_AUDIT_TRUST_POLICY" "arn:aws:iam::aws:policy/service-role/AWSIoTDeviceDefenderAudit"
AUDIT_ROLE_ARN=$ROLE_ARN
CREATED_RESOURCES+=("IAM Role: AWSIoTDeviceDefenderAuditRole")

# Create IoT Logging role
IOT_LOGGING_TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "iot.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'

create_iam_role "AWSIoTLoggingRole" "$IOT_LOGGING_TRUST_POLICY" ""
LOGGING_ROLE_ARN=$ROLE_ARN
CREATED_RESOURCES+=("IAM Role: AWSIoTLoggingRole")

# Create IoT Mitigation Action role
IOT_MITIGATION_TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "iot.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'

create_iam_role "IoTMitigationActionErrorLoggingRole" "$IOT_MITIGATION_TRUST_POLICY" ""
MITIGATION_ROLE_ARN=$ROLE_ARN
CREATED_RESOURCES+=("IAM Role: IoTMitigationActionErrorLoggingRole")

# Step 2: Enable audit checks
echo ""
echo "==================================================="
echo "Step 2: Enabling AWS IoT Device Defender audit checks"
echo "==================================================="

# Get current audit configuration
echo "Getting current audit configuration..."
CURRENT_CONFIG=$(aws iot describe-account-audit-configuration)
echo "$CURRENT_CONFIG"

# Enable specific audit checks
echo "Enabling audit checks..."
UPDATE_RESULT=$(aws iot update-account-audit-configuration \
  --role-arn "$AUDIT_ROLE_ARN" \
  --audit-check-configurations '{"LOGGING_DISABLED_CHECK":{"enabled":true}}')

if ! check_error "$UPDATE_RESULT"; then
    echo "Failed to update audit configuration"
    exit 1
fi

echo "Audit checks enabled successfully"

# Step 3: Run an on-demand audit
echo ""
echo "==================================================="
echo "Step 3: Running an on-demand audit"
echo "==================================================="

echo "Starting on-demand audit task..."
AUDIT_TASK_RESULT=$(aws iot start-on-demand-audit-task \
  --target-check-names LOGGING_DISABLED_CHECK)

if ! check_error "$AUDIT_TASK_RESULT"; then
    echo "Failed to start on-demand audit task"
    exit 1
fi

TASK_ID=$(echo "$AUDIT_TASK_RESULT" | grep -o '"taskId": "[^"]*' | cut -d'"' -f4)
echo "Audit task started with ID: $TASK_ID"
CREATED_RESOURCES+=("Audit Task: $TASK_ID")

# Wait for the audit task to complete
echo "Waiting for audit task to complete (this may take a few minutes)..."
TASK_STATUS="IN_PROGRESS"
while [ "$TASK_STATUS" != "COMPLETED" ]; do
    sleep 10
    TASK_DETAILS=$(aws iot describe-audit-task --task-id "$TASK_ID")
    TASK_STATUS=$(echo "$TASK_DETAILS" | grep -o '"taskStatus": "[^"]*' | cut -d'"' -f4)
    echo "Current task status: $TASK_STATUS"
    
    if [ "$TASK_STATUS" == "FAILED" ]; then
        echo "Audit task failed"
        exit 1
    fi
done

echo "Audit task completed successfully"

# Get audit findings
echo "Getting audit findings..."
FINDINGS=$(aws iot list-audit-findings \
  --task-id "$TASK_ID")

echo "Audit findings:"
echo "$FINDINGS"

# Check if we have any non-compliant findings
if echo "$FINDINGS" | grep -q '"findingId"'; then
    FINDING_ID=$(echo "$FINDINGS" | grep -o '"findingId": "[^"]*' | head -1 | cut -d'"' -f4)
    echo "Found non-compliant finding with ID: $FINDING_ID"
    HAS_FINDINGS=true
else
    echo "No non-compliant findings detected"
    HAS_FINDINGS=false
fi

# Step 4: Create a mitigation action
echo ""
echo "==================================================="
echo "Step 4: Creating a mitigation action"
echo "==================================================="

# Check if mitigation action already exists
MITIGATION_EXISTS=$(aws iot list-mitigation-actions --action-name "EnableErrorLoggingAction" 2>&1)
if echo "$MITIGATION_EXISTS" | grep -q "EnableErrorLoggingAction"; then
    echo "Mitigation action 'EnableErrorLoggingAction' already exists, deleting it first..."
    aws iot delete-mitigation-action --action-name "EnableErrorLoggingAction"
    # Wait a moment for deletion to complete
    sleep 5
fi

echo "Creating mitigation action to enable AWS IoT logging..."
MITIGATION_RESULT=$(aws iot create-mitigation-action \
  --action-name "EnableErrorLoggingAction" \
  --role-arn "$MITIGATION_ROLE_ARN" \
  --action-params "{\"enableIoTLoggingParams\":{\"roleArnForLogging\":\"$LOGGING_ROLE_ARN\",\"logLevel\":\"ERROR\"}}")

echo "$MITIGATION_RESULT"
if ! check_error "$MITIGATION_RESULT"; then
    echo "Failed to create mitigation action"
    exit 1
fi

echo "Mitigation action created successfully"
CREATED_RESOURCES+=("Mitigation Action: EnableErrorLoggingAction")

# Step 5: Apply mitigation action to findings (if any)
if [ "$HAS_FINDINGS" = true ]; then
    echo ""
    echo "==================================================="
    echo "Step 5: Applying mitigation action to findings"
    echo "==================================================="

    MITIGATION_TASK_ID="MitigationTask-$(date +%s)"
    echo "Starting mitigation actions task with ID: $MITIGATION_TASK_ID"
    
    MITIGATION_TASK_RESULT=$(aws iot start-audit-mitigation-actions-task \
      --task-id "$MITIGATION_TASK_ID" \
      --target "{\"findingIds\":[\"$FINDING_ID\"]}" \
      --audit-check-to-actions-mapping "{\"LOGGING_DISABLED_CHECK\":[\"EnableErrorLoggingAction\"]}")

    if ! check_error "$MITIGATION_TASK_RESULT"; then
        echo "Failed to start mitigation actions task"
        exit 1
    fi

    echo "Mitigation actions task started successfully"
    CREATED_RESOURCES+=("Mitigation Task: $MITIGATION_TASK_ID")
    
    # Wait for the mitigation task to complete
    echo "Waiting for mitigation task to complete..."
    sleep 10
    
    # Use a more reliable date format for the API call
    START_TIME=$(date -u -d 'today' '+%Y-%m-%dT%H:%M:%S.000Z')
    END_TIME=$(date -u -d 'tomorrow' '+%Y-%m-%dT%H:%M:%S.000Z')
    
    MITIGATION_TASKS=$(aws iot list-audit-mitigation-actions-tasks \
      --start-time "$START_TIME" \
      --end-time "$END_TIME" 2>&1)
    
    if check_error "$MITIGATION_TASKS"; then
        echo "Mitigation tasks:"
        echo "$MITIGATION_TASKS"
    else
        echo "Could not retrieve mitigation task status, but task was started successfully"
    fi
else
    echo ""
    echo "==================================================="
    echo "Step 5: Skipping mitigation action application (no findings)"
    echo "==================================================="
fi

# Step 6: Set up SNS notifications (optional)
echo ""
echo "==================================================="
echo "Step 6: Setting up SNS notifications"
echo "==================================================="

# Check if SNS topic already exists
SNS_TOPICS=$(aws sns list-topics)
if echo "$SNS_TOPICS" | grep -q "IoTDDNotifications"; then
    echo "SNS topic 'IoTDDNotifications' already exists, using existing topic..."
    TOPIC_ARN=$(echo "$SNS_TOPICS" | grep -o '"TopicArn": "[^"]*IoTDDNotifications' | cut -d'"' -f4)
else
    echo "Creating SNS topic for notifications..."
    SNS_RESULT=$(aws sns create-topic --name "IoTDDNotifications")

    if ! check_error "$SNS_RESULT"; then
        echo "Failed to create SNS topic"
        exit 1
    fi

    TOPIC_ARN=$(echo "$SNS_RESULT" | grep -o '"TopicArn": "[^"]*' | cut -d'"' -f4)
    echo "SNS topic created with ARN: $TOPIC_ARN"
    CREATED_RESOURCES+=("SNS Topic: IoTDDNotifications")
fi

echo "Updating audit configuration to enable SNS notifications..."
SNS_UPDATE_RESULT=$(aws iot update-account-audit-configuration \
  --audit-notification-target-configurations "{\"SNS\":{\"targetArn\":\"$TOPIC_ARN\",\"roleArn\":\"$AUDIT_ROLE_ARN\",\"enabled\":true}}")

if ! check_error "$SNS_UPDATE_RESULT"; then
    echo "Failed to update audit configuration for SNS notifications"
    exit 1
fi

echo "SNS notifications enabled successfully"

# Step 7: Enable AWS IoT logging
echo ""
echo "==================================================="
echo "Step 7: Enabling AWS IoT logging"
echo "==================================================="

echo "Setting up AWS IoT logging options..."

# Create the logging options payload
LOGGING_OPTIONS_PAYLOAD="{\"roleArn\":\"$LOGGING_ROLE_ARN\",\"logLevel\":\"ERROR\"}"

LOGGING_RESULT=$(aws iot set-v2-logging-options \
  --role-arn "$LOGGING_ROLE_ARN" \
  --default-log-level "ERROR" 2>&1)

if ! check_error "$LOGGING_RESULT"; then
    echo "Failed to set up AWS IoT v2 logging, trying v1 logging..."
    
    # Try the older set-logging-options command with proper payload format
    LOGGING_RESULT_V1=$(aws iot set-logging-options \
      --logging-options-payload "$LOGGING_OPTIONS_PAYLOAD" 2>&1)
    
    if ! check_error "$LOGGING_RESULT_V1"; then
        echo "Failed to set up AWS IoT logging with both v1 and v2 methods"
        echo "V2 result: $LOGGING_RESULT"
        echo "V1 result: $LOGGING_RESULT_V1"
        exit 1
    else
        echo "AWS IoT v1 logging enabled successfully"
    fi
else
    echo "AWS IoT v2 logging enabled successfully"
fi

# Verify logging is enabled
echo "Verifying logging configuration..."
LOGGING_CONFIG=$(aws iot get-v2-logging-options 2>&1)
if check_error "$LOGGING_CONFIG"; then
    echo "V2 Logging configuration:"
    echo "$LOGGING_CONFIG"
else
    echo "Checking v1 logging configuration..."
    LOGGING_CONFIG_V1=$(aws iot get-logging-options 2>&1)
    if check_error "$LOGGING_CONFIG_V1"; then
        echo "V1 Logging configuration:"
        echo "$LOGGING_CONFIG_V1"
    else
        echo "Could not retrieve logging configuration"
    fi
fi

# Script completed successfully
echo ""
echo "==================================================="
echo "AWS IoT Device Defender setup completed successfully!"
echo "==================================================="
echo "The following resources were created:"
for resource in "${CREATED_RESOURCES[@]}"; do
    echo "- $resource"
done
echo ""

# Ask if user wants to clean up resources
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ $CLEANUP_CHOICE =~ ^[Yy]$ ]]; then
    echo "Starting cleanup process..."
    
    # Disable AWS IoT logging
    echo "Disabling AWS IoT logging..."
    
    # Try to disable v2 logging first
    DISABLE_V2_RESULT=$(aws iot set-v2-logging-options \
      --default-log-level "DISABLED" 2>&1)
    
    if ! check_error "$DISABLE_V2_RESULT"; then
        echo "Failed to disable v2 logging, trying v1..."
        # Try v1 logging disable
        DISABLE_V1_RESULT=$(aws iot set-logging-options \
          --logging-options-payload "{\"logLevel\":\"DISABLED\"}" 2>&1)
        
        if ! check_error "$DISABLE_V1_RESULT"; then
            echo "Warning: Could not disable logging through either v1 or v2 methods"
        else
            echo "V1 logging disabled successfully"
        fi
    else
        echo "V2 logging disabled successfully"
    fi
    
    # Delete mitigation action
    echo "Deleting mitigation action..."
    aws iot delete-mitigation-action --action-name "EnableErrorLoggingAction"
    
    # Delete SNS topic
    echo "Deleting SNS topic..."
    aws sns delete-topic --topic-arn "$TOPIC_ARN"
    
    # Detach policies from roles and delete roles (in reverse order)
    echo "Cleaning up IAM roles..."
    
    # Check if policies exist before trying to delete them
    ROLE_POLICIES=$(aws iam list-role-policies --role-name "IoTMitigationActionErrorLoggingRole" 2>&1)
    if ! echo "$ROLE_POLICIES" | grep -q "NoSuchEntity"; then
        if echo "$ROLE_POLICIES" | grep -q "IoTMitigationActionErrorLoggingRolePolicy"; then
            aws iam delete-role-policy \
                --role-name "IoTMitigationActionErrorLoggingRole" \
                --policy-name "IoTMitigationActionErrorLoggingRolePolicy"
        fi
    fi
    aws iam delete-role --role-name "IoTMitigationActionErrorLoggingRole"
    
    ROLE_POLICIES=$(aws iam list-role-policies --role-name "AWSIoTLoggingRole" 2>&1)
    if ! echo "$ROLE_POLICIES" | grep -q "NoSuchEntity"; then
        if echo "$ROLE_POLICIES" | grep -q "AWSIoTLoggingRolePolicy"; then
            aws iam delete-role-policy \
                --role-name "AWSIoTLoggingRole" \
                --policy-name "AWSIoTLoggingRolePolicy"
        fi
    fi
    aws iam delete-role --role-name "AWSIoTLoggingRole"
    
    aws iam detach-role-policy \
        --role-name "AWSIoTDeviceDefenderAuditRole" \
        --policy-arn "arn:aws:iam::aws:policy/service-role/AWSIoTDeviceDefenderAudit"
    aws iam delete-role --role-name "AWSIoTDeviceDefenderAuditRole"
    
    echo "Cleanup completed successfully"
else
    echo "Skipping cleanup. Resources will remain in your AWS account."
fi

echo ""
echo "Script execution completed at $(date)"
echo "Log file: $LOG_FILE"
