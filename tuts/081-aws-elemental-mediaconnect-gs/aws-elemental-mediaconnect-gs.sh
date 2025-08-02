#!/bin/bash

# AWS Elemental MediaConnect Getting Started Tutorial Script
# This script creates a MediaConnect flow, adds an output, grants an entitlement,
# and then cleans up the resources.

# Set up logging
LOG_FILE="mediaconnect-tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting AWS Elemental MediaConnect tutorial script at $(date)"
echo "All commands and outputs will be logged to $LOG_FILE"

# Function to handle errors
handle_error() {
    echo "ERROR: $1"
    echo "Attempting to clean up resources..."
    cleanup_resources
    exit 1
}

# Function to clean up resources
cleanup_resources() {
    echo "Cleaning up resources..."
    
    if [ -n "$FLOW_ARN" ]; then
        # Check flow status before attempting to stop
        echo "Checking flow status..."
        FLOW_STATUS_OUTPUT=$(aws mediaconnect describe-flow --flow-arn "$FLOW_ARN" --query "Flow.Status" --output text 2>&1)
        echo "Current flow status: $FLOW_STATUS_OUTPUT"
        
        if [ "$FLOW_STATUS_OUTPUT" == "ACTIVE" ] || [ "$FLOW_STATUS_OUTPUT" == "UPDATING" ]; then
            echo "Stopping flow: $FLOW_ARN"
            STOP_FLOW_OUTPUT=$(aws mediaconnect stop-flow --flow-arn "$FLOW_ARN" 2>&1)
            if echo "$STOP_FLOW_OUTPUT" | grep -i "error" > /dev/null; then
                echo "WARNING: Failed to stop flow. Output: $STOP_FLOW_OUTPUT"
                echo "Attempting to delete anyway..."
            else
                echo "$STOP_FLOW_OUTPUT"
                
                # Wait for flow to stop before deleting
                echo "Waiting for flow to stop..."
                sleep 10
            fi
        else
            echo "Flow is not in ACTIVE or UPDATING state, skipping stop operation."
        fi
        
        # Delete the flow
        echo "Deleting flow: $FLOW_ARN"
        DELETE_FLOW_OUTPUT=$(aws mediaconnect delete-flow --flow-arn "$FLOW_ARN" 2>&1)
        if echo "$DELETE_FLOW_OUTPUT" | grep -i "error" > /dev/null; then
            echo "WARNING: Failed to delete flow. Output: $DELETE_FLOW_OUTPUT"
            echo "You may need to manually delete the flow from the AWS console."
        else
            echo "$DELETE_FLOW_OUTPUT"
        fi
    fi
}

# Get the current AWS region
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    handle_error "Failed to get AWS region. Please make sure AWS CLI is configured."
fi
echo "Using AWS Region: $AWS_REGION"

# Get available availability zones in the current region
echo "Getting available availability zones in region $AWS_REGION..."
AZ_OUTPUT=$(aws ec2 describe-availability-zones --region "$AWS_REGION" --query "AvailabilityZones[0].ZoneName" --output text 2>&1)
if echo "$AZ_OUTPUT" | grep -i "error" > /dev/null; then
    handle_error "Failed to get availability zones. Output: $AZ_OUTPUT"
fi
AVAILABILITY_ZONE="$AZ_OUTPUT"
echo "Using availability zone: $AVAILABILITY_ZONE"

# Generate a unique suffix for resource names
SUFFIX=$(date +%s | cut -c 6-10)
FLOW_NAME="AwardsNYCShow-${SUFFIX}"
SOURCE_NAME="AwardsNYCSource-${SUFFIX}"
OUTPUT_NAME="AwardsNYCOutput-${SUFFIX}"
ENTITLEMENT_NAME="PhillyTeam-${SUFFIX}"

echo "Using the following resource names:"
echo "Flow name: $FLOW_NAME"
echo "Source name: $SOURCE_NAME"
echo "Output name: $OUTPUT_NAME"
echo "Entitlement name: $ENTITLEMENT_NAME"

# Step 1: Verify access to MediaConnect
echo "Step 1: Verifying access to AWS Elemental MediaConnect..."
LIST_FLOWS_OUTPUT=$(aws mediaconnect list-flows 2>&1)
if echo "$LIST_FLOWS_OUTPUT" | grep -i "error" > /dev/null; then
    handle_error "Failed to list flows. Please check your AWS credentials and permissions. Output: $LIST_FLOWS_OUTPUT"
fi
echo "$LIST_FLOWS_OUTPUT"

# Step 2: Create a flow
echo "Step 2: Creating a flow..."
CREATE_FLOW_OUTPUT=$(aws mediaconnect create-flow \
    --availability-zone "$AVAILABILITY_ZONE" \
    --name "$FLOW_NAME" \
    --source "Name=$SOURCE_NAME,Protocol=zixi-push,WhitelistCidr=10.24.34.0/23,StreamId=ZixiAwardsNYCFeed" 2>&1)

if echo "$CREATE_FLOW_OUTPUT" | grep -i "error" > /dev/null; then
    handle_error "Failed to create flow. Output: $CREATE_FLOW_OUTPUT"
fi
echo "$CREATE_FLOW_OUTPUT"

# Extract the flow ARN from the output
FLOW_ARN=$(echo "$CREATE_FLOW_OUTPUT" | grep -o '"FlowArn": "[^"]*' | cut -d'"' -f4)
if [ -z "$FLOW_ARN" ]; then
    handle_error "Failed to extract flow ARN from output"
fi
echo "Flow ARN: $FLOW_ARN"

# Step 3: Add an output
echo "Step 3: Adding an output to the flow..."
ADD_OUTPUT_OUTPUT=$(aws mediaconnect add-flow-outputs \
    --flow-arn "$FLOW_ARN" \
    --outputs "Name=$OUTPUT_NAME,Protocol=zixi-push,Destination=198.51.100.11,Port=1024,StreamId=ZixiAwardsOutput" 2>&1)

if echo "$ADD_OUTPUT_OUTPUT" | grep -i "error" > /dev/null; then
    handle_error "Failed to add output to flow. Output: $ADD_OUTPUT_OUTPUT"
fi
echo "$ADD_OUTPUT_OUTPUT"

# Extract the output ARN
OUTPUT_ARN=$(echo "$ADD_OUTPUT_OUTPUT" | grep -o '"OutputArn": "[^"]*' | cut -d'"' -f4)
echo "Output ARN: $OUTPUT_ARN"

# Step 4: Grant an entitlement
echo "Step 4: Granting an entitlement..."
GRANT_ENTITLEMENT_OUTPUT=$(aws mediaconnect grant-flow-entitlements \
    --flow-arn "$FLOW_ARN" \
    --entitlements "Name=$ENTITLEMENT_NAME,Subscribers=222233334444" 2>&1)

if echo "$GRANT_ENTITLEMENT_OUTPUT" | grep -i "error" > /dev/null; then
    handle_error "Failed to grant entitlement. Output: $GRANT_ENTITLEMENT_OUTPUT"
fi
echo "$GRANT_ENTITLEMENT_OUTPUT"

# Extract the entitlement ARN
ENTITLEMENT_ARN=$(echo "$GRANT_ENTITLEMENT_OUTPUT" | grep -o '"EntitlementArn": "[^"]*' | cut -d'"' -f4)
echo "Entitlement ARN: $ENTITLEMENT_ARN"

# Step 5: List entitlements to share with affiliates
echo "Step 5: Listing entitlements for the flow..."
DESCRIBE_FLOW_OUTPUT=$(aws mediaconnect describe-flow --flow-arn "$FLOW_ARN" --query "Flow.Entitlements" 2>&1)
if echo "$DESCRIBE_FLOW_OUTPUT" | grep -i "error" > /dev/null; then
    handle_error "Failed to describe flow. Output: $DESCRIBE_FLOW_OUTPUT"
fi
echo "Entitlements for the flow:"
echo "$DESCRIBE_FLOW_OUTPUT"

# Display information to share with affiliates
echo ""
echo "Information to share with your Philadelphia affiliate:"
echo "Entitlement ARN: $ENTITLEMENT_ARN"
echo "AWS Region: $AWS_REGION"

# Prompt user before cleanup
echo ""
echo "==========================================="
echo "RESOURCE SUMMARY"
echo "==========================================="
echo "The following resources were created:"
echo "1. Flow: $FLOW_NAME (ARN: $FLOW_ARN)"
echo "2. Output: $OUTPUT_NAME (ARN: $OUTPUT_ARN)"
echo "3. Entitlement: $ENTITLEMENT_NAME (ARN: $ENTITLEMENT_ARN)"
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    # Step 6: Clean up resources
    echo "Step 6: Cleaning up resources..."
    
    # Check flow status before attempting to stop
    echo "Checking flow status..."
    FLOW_STATUS_OUTPUT=$(aws mediaconnect describe-flow --flow-arn "$FLOW_ARN" --query "Flow.Status" --output text 2>&1)
    echo "Current flow status: $FLOW_STATUS_OUTPUT"
    
    if [ "$FLOW_STATUS_OUTPUT" == "ACTIVE" ] || [ "$FLOW_STATUS_OUTPUT" == "UPDATING" ]; then
        echo "Stopping flow: $FLOW_ARN"
        STOP_FLOW_OUTPUT=$(aws mediaconnect stop-flow --flow-arn "$FLOW_ARN" 2>&1)
        if echo "$STOP_FLOW_OUTPUT" | grep -i "error" > /dev/null; then
            echo "WARNING: Failed to stop flow. Output: $STOP_FLOW_OUTPUT"
            echo "Attempting to delete anyway..."
        else
            echo "$STOP_FLOW_OUTPUT"
            
            # Wait for flow to stop before deleting
            echo "Waiting for flow to stop..."
            sleep 10
        fi
    else
        echo "Flow is not in ACTIVE or UPDATING state, skipping stop operation."
    fi
    
    # Delete the flow
    echo "Deleting flow: $FLOW_ARN"
    DELETE_FLOW_OUTPUT=$(aws mediaconnect delete-flow --flow-arn "$FLOW_ARN" 2>&1)
    if echo "$DELETE_FLOW_OUTPUT" | grep -i "error" > /dev/null; then
        echo "WARNING: Failed to delete flow. Output: $DELETE_FLOW_OUTPUT"
        echo "You may need to manually delete the flow from the AWS console."
    else
        echo "$DELETE_FLOW_OUTPUT"
    fi
    
    echo "Cleanup completed."
else
    echo "Skipping cleanup. Resources will remain in your AWS account."
    echo "To clean up later, you'll need to manually stop and delete the flow using the AWS console or CLI."
fi

echo "Script completed at $(date)"
