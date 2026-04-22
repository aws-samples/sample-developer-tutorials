#!/bin/bash

# Amazon SNS Getting Started Script
# This script demonstrates how to create an SNS topic, subscribe to it, publish a message,
# and clean up resources.

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
    if [ -n "$SUBSCRIPTION_ARN" ] && [ "$SUBSCRIPTION_ARN" != "pending confirmation" ]; then
        echo "Deleting subscription: $SUBSCRIPTION_ARN"
        aws sns unsubscribe --subscription-arn "$SUBSCRIPTION_ARN"
    fi
    
    if [ -n "$TOPIC_ARN" ]; then
        echo "Deleting topic: $TOPIC_ARN"
        aws sns delete-topic --topic-arn "$TOPIC_ARN"
    fi
}

# Generate a random topic name suffix
RANDOM_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
TOPIC_NAME="my-topic-${RANDOM_SUFFIX}"

# Step 1: Create an SNS topic
echo "Creating SNS topic: $TOPIC_NAME"
TOPIC_RESULT=$(aws sns create-topic --name "$TOPIC_NAME" --tags Key=tutorial,Value=amazon-simple-notification-service-gs)

# Check for errors
if echo "$TOPIC_RESULT" | grep -i "error" > /dev/null; then
    handle_error "Failed to create SNS topic: $TOPIC_RESULT"
fi

# Extract the topic ARN
TOPIC_ARN=$(echo "$TOPIC_RESULT" | grep -o '"TopicArn": "[^"]*' | cut -d'"' -f4)

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
if [ -t 0 ]; then
    read -r EMAIL_ADDRESS
else
    EMAIL_ADDRESS="test@example.com"
fi

echo "Subscribing email: $EMAIL_ADDRESS to topic"
SUBSCRIPTION_RESULT=$(aws sns subscribe \
    --topic-arn "$TOPIC_ARN" \
    --protocol email \
    --notification-endpoint "$EMAIL_ADDRESS")

# Check for errors
if echo "$SUBSCRIPTION_RESULT" | grep -i "error" > /dev/null; then
    handle_error "Failed to create subscription: $SUBSCRIPTION_RESULT"
fi

# Extract the subscription ARN (will be "pending confirmation")
SUBSCRIPTION_ARN=$(echo "$SUBSCRIPTION_RESULT" | grep -o '"SubscriptionArn": "[^"]*' | cut -d'"' -f4)

echo "Subscription created: $SUBSCRIPTION_ARN"
echo "A confirmation email has been sent to $EMAIL_ADDRESS"
echo "Please check your email and confirm the subscription."
echo ""
echo "Waiting for you to confirm the subscription..."
echo "Press Enter after you have confirmed the subscription to continue:"
if [ -t 0 ]; then
    read -r
fi

# Step 3: List subscriptions to verify
echo "Listing subscriptions for topic: $TOPIC_ARN"
SUBSCRIPTIONS=$(aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN")

# Check for errors
if echo "$SUBSCRIPTIONS" | grep -i "error" > /dev/null; then
    handle_error "Failed to list subscriptions: $SUBSCRIPTIONS"
fi

echo "Current subscriptions:"
echo "$SUBSCRIPTIONS"

# Get the confirmed subscription ARN
SUBSCRIPTION_ARN=$(echo "$SUBSCRIPTIONS" | grep -o '"SubscriptionArn": "[^"]*' | grep -v "pending confirmation" | head -1 | cut -d'"' -f4)

if [ -z "$SUBSCRIPTION_ARN" ] || [ "$SUBSCRIPTION_ARN" == "pending confirmation" ]; then
    echo "Warning: No confirmed subscription found. You may not have confirmed the subscription yet."
    echo "The script will continue, but you may not receive the test message."
fi

# Step 4: Publish a message to the topic
echo ""
echo "Publishing a test message to the topic"
MESSAGE="Hello from Amazon SNS! This is a test message sent at $(date)."
PUBLISH_RESULT=$(aws sns publish \
    --topic-arn "$TOPIC_ARN" \
    --message "$MESSAGE")

# Check for errors
if echo "$PUBLISH_RESULT" | grep -i "error" > /dev/null; then
    handle_error "Failed to publish message: $PUBLISH_RESULT"
fi

MESSAGE_ID=$(echo "$PUBLISH_RESULT" | grep -o '"MessageId": "[^"]*' | cut -d'"' -f4)
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
echo "- Subscription: $SUBSCRIPTION_ARN"
echo ""
echo "Do you want to clean up all created resources? (y/n):"
if [ -t 0 ]; then
    read -rp "" CLEANUP_CHOICE
else
    CLEANUP_CHOICE=y
fi

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    echo "Cleaning up resources..."
    cleanup_resources
    echo "Cleanup completed successfully."
else
    echo "Skipping cleanup. Resources will remain in your AWS account."
    echo "To clean up later, use the following commands:"
    echo "aws sns unsubscribe --subscription-arn $SUBSCRIPTION_ARN"
    echo "aws sns delete-topic --topic-arn $TOPIC_ARN"
fi

echo ""
echo "Tutorial completed successfully!"
echo "$(date)"
echo "=============================================="