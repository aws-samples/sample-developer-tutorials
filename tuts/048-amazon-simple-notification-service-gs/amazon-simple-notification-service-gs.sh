#!/bin/bash

# Amazon SNS Getting Started Script
# This script demonstrates how to create an SNS topic, subscribe to it, publish a message,
# and clean up resources.

set -euo pipefail

# Set up logging
LOG_FILE="sns-tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Amazon SNS Getting Started Tutorial..."
echo "$(date)"
echo "=============================================="

# Function to handle errors
handle_error() {
    echo "ERROR: $1"
    echo "Attempting to clean up resources..."
    cleanup_resources
    exit 1
}

# Function to clean up resources
cleanup_resources() {
    if [ -n "${SUBSCRIPTION_ARN:-}" ] && [ "$SUBSCRIPTION_ARN" != "pending confirmation" ]; then
        echo "Deleting subscription: $SUBSCRIPTION_ARN"
        aws sns unsubscribe --subscription-arn "$SUBSCRIPTION_ARN" 2>/dev/null || true
    fi
    
    if [ -n "${TOPIC_ARN:-}" ]; then
        echo "Deleting topic: $TOPIC_ARN"
        aws sns delete-topic --topic-arn "$TOPIC_ARN" 2>/dev/null || true
    fi
}

# Set trap for cleanup on exit
trap cleanup_resources EXIT

# Validate AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    handle_error "AWS CLI is not installed or not in PATH"
fi

if ! aws sts get-caller-identity &> /dev/null; then
    handle_error "AWS CLI is not configured correctly. Please run 'aws configure'"
fi

# Generate a random topic name suffix using secure method
RANDOM_SUFFIX=$(head -c 8 /dev/urandom | base64 | tr -dc 'a-z0-9' | head -c 8)
TOPIC_NAME="my-topic-${RANDOM_SUFFIX}"

# Step 1: Create an SNS topic
echo "Creating SNS topic: $TOPIC_NAME"
TOPIC_RESULT=$(aws sns create-topic --name "$TOPIC_NAME" \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=amazon-simple-notification-service-gs \
    --output json 2>&1) || handle_error "Failed to create SNS topic"

# Extract the topic ARN using jq for safe parsing
TOPIC_ARN=$(echo "$TOPIC_RESULT" | jq -r '.TopicArn // empty' 2>/dev/null)

if [ -z "$TOPIC_ARN" ]; then
    handle_error "Failed to extract topic ARN from result: $TOPIC_RESULT"
fi

echo "Successfully created topic with ARN: $TOPIC_ARN"

# Step 2: Subscribe to the topic
echo ""
echo "=============================================="
echo "EMAIL SUBSCRIPTION"
echo "=============================================="
echo "Please enter your email address to subscribe to the topic:"
read -r EMAIL_ADDRESS

# Validate email format
if ! [[ "$EMAIL_ADDRESS" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    handle_error "Invalid email address format: $EMAIL_ADDRESS"
fi

echo "Subscribing email: $EMAIL_ADDRESS to topic"
SUBSCRIPTION_RESULT=$(aws sns subscribe \
    --topic-arn "$TOPIC_ARN" \
    --protocol email \
    --notification-endpoint "$EMAIL_ADDRESS" \
    --output json 2>&1) || handle_error "Failed to create subscription"

# Extract the subscription ARN using jq for safe parsing
SUBSCRIPTION_ARN=$(echo "$SUBSCRIPTION_RESULT" | jq -r '.SubscriptionArn // empty' 2>/dev/null)

echo "Subscription created: $SUBSCRIPTION_ARN"
echo "A confirmation email has been sent to $EMAIL_ADDRESS"
echo "Please check your email and confirm the subscription."
echo ""
echo "Waiting for you to confirm the subscription..."
echo "Press Enter after you have confirmed the subscription to continue:"
read -r

# Step 3: List subscriptions to verify
echo "Listing subscriptions for topic: $TOPIC_ARN"
SUBSCRIPTIONS=$(aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" \
    --output json 2>&1) || handle_error "Failed to list subscriptions"

echo "Current subscriptions:"
echo "$SUBSCRIPTIONS" | jq '.'

# Get the confirmed subscription ARN using jq for safe parsing
SUBSCRIPTION_ARN=$(echo "$SUBSCRIPTIONS" | jq -r '.Subscriptions[] | select(.SubscriptionArn != "PendingConfirmation") | .SubscriptionArn | first' 2>/dev/null || echo "")

if [ -z "$SUBSCRIPTION_ARN" ] || [ "$SUBSCRIPTION_ARN" == "PendingConfirmation" ]; then
    echo "Warning: No confirmed subscription found. You may not have confirmed the subscription yet."
    echo "The script will continue, but you may not receive the test message."
fi

# Step 4: Publish a message to the topic
echo ""
echo "Publishing a test message to the topic"
MESSAGE="Hello from Amazon SNS! This is a test message sent at $(date)."
PUBLISH_RESULT=$(aws sns publish \
    --topic-arn "$TOPIC_ARN" \
    --message "$MESSAGE" \
    --output json 2>&1) || handle_error "Failed to publish message"

MESSAGE_ID=$(echo "$PUBLISH_RESULT" | jq -r '.MessageId // empty' 2>/dev/null)
echo "Message published successfully with ID: $MESSAGE_ID"
echo "Check your email for the message."

# Pause to allow the user to check their email
echo ""
echo "Pausing for 10 seconds to allow message delivery..."
sleep 10

# Step 5: Clean up resources
echo ""
echo "=============================================="
echo "CLEANUP CONFIRMATION"
echo "=============================================="
echo "Resources created:"
echo "- SNS Topic: $TOPIC_ARN"
echo "- Subscription: ${SUBSCRIPTION_ARN:-none confirmed}"
echo ""
echo "Do you want to clean up all created resources? (y/n):"
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    echo "Cleaning up resources..."
    cleanup_resources
    echo "Cleanup completed successfully."
else
    echo "Skipping cleanup. Resources will remain in your AWS account."
    echo "To clean up later, use the following commands:"
    if [ -n "${SUBSCRIPTION_ARN:-}" ]; then
        echo "aws sns unsubscribe --subscription-arn '$SUBSCRIPTION_ARN'"
    fi
    echo "aws sns delete-topic --topic-arn '$TOPIC_ARN'"
fi

echo ""
echo "Tutorial completed successfully!"
echo "$(date)"
echo "=============================================="