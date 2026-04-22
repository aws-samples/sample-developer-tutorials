#!/bin/bash

# AWS Marketplace Buyer Getting Started Script
# This script demonstrates how to search for products in AWS Marketplace,
# launch an EC2 instance with a product AMI, and manage subscriptions.

# Setup logging
LOG_FILE="marketplace-tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==================================================="
echo "AWS Marketplace Buyer Getting Started Tutorial"
echo "==================================================="
echo "This script will:"
echo "1. List available products in AWS Marketplace"
echo "2. Create resources needed to launch an EC2 instance"
echo "3. Launch an EC2 instance with an Amazon Linux 2 AMI"
echo "4. Show how to manage and terminate the instance"
echo "==================================================="
echo ""

# Function to check for errors in command output
check_error() {
    local output=$1
    local cmd=$2
    
    if echo "$output" | grep -i "error" > /dev/null; then
        echo "ERROR: Command failed: $cmd"
        echo "Output: $output"
        cleanup_resources
        exit 1
    fi
}

# Function to clean up resources
cleanup_resources() {
    echo ""
    echo "==================================================="
    echo "CLEANING UP RESOURCES"
    echo "==================================================="
    
    if [ -n "$INSTANCE_ID" ]; then
        echo "Terminating EC2 instance: $INSTANCE_ID"
        aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
        
        echo "Waiting for instance to terminate..."
        aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
        echo "Instance terminated successfully."
    fi
    
    if [ -n "$SECURITY_GROUP_ID" ]; then
        echo "Deleting security group: $SECURITY_GROUP_ID"
        aws ec2 delete-security-group --group-id "$SECURITY_GROUP_ID"
        echo "Security group deleted."
    fi
    
    if [ -n "$KEY_NAME" ]; then
        echo "Deleting key pair: $KEY_NAME"
        aws ec2 delete-key-pair --key-name "$KEY_NAME"
        
        # Remove the local key file if it exists
        if [ -f "${KEY_NAME}.pem" ]; then
            rm "${KEY_NAME}.pem"
            echo "Local key file deleted."
        fi
    fi
    
    echo "Cleanup completed."
}

# Generate random identifier for resource names
RANDOM_ID=$(openssl rand -hex 6)
KEY_NAME="marketplace-key-${RANDOM_ID}"
SECURITY_GROUP_NAME="marketplace-sg-${RANDOM_ID}"

# Initialize variables to track created resources
INSTANCE_ID=""
SECURITY_GROUP_ID=""

# Step 1: List available products in AWS Marketplace
echo "Listing available products in AWS Marketplace..."
echo "Note: In a real scenario, you would use marketplace-catalog commands to list and search for products."
echo "However, this requires specific permissions and product knowledge."
echo ""
echo "For this tutorial, we'll use a public Amazon Linux 2 AMI instead of an actual marketplace product."
echo "This is because subscribing to marketplace products requires accepting terms via the console."
echo ""

# Step 2: Create a key pair for SSH access
echo "Creating key pair: $KEY_NAME"
KEY_OUTPUT=$(aws ec2 create-key-pair \
  --key-name "$KEY_NAME" \
  --query 'KeyMaterial' \
  --output text > "${KEY_NAME}.pem" 2>&1)

check_error "$KEY_OUTPUT" "ec2 create-key-pair"

# Set proper permissions for the key file
chmod 400 "${KEY_NAME}.pem"
echo "Key pair created and saved to ${KEY_NAME}.pem"

# Step 3: Create a security group
echo "Creating security group: $SECURITY_GROUP_NAME"
SG_OUTPUT=$(aws ec2 create-security-group \
  --group-name "$SECURITY_GROUP_NAME" \
  --description "Security group for AWS Marketplace tutorial" \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=tutorial,Value=marketplace-buyer-gs}]' 2>&1)

check_error "$SG_OUTPUT" "ec2 create-security-group"

# Extract security group ID
SECURITY_GROUP_ID=$(echo "$SG_OUTPUT" | grep -o '"GroupId": "[^"]*' | cut -d'"' -f4)
echo "Security group created with ID: $SECURITY_GROUP_ID"

# Add inbound rule for SSH (port 22)
echo "Adding inbound rule for SSH (port 22)..."
SSH_RULE_OUTPUT=$(aws ec2 authorize-security-group-ingress \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 10.0.0.0/16 2>&1)

check_error "$SSH_RULE_OUTPUT" "ec2 authorize-security-group-ingress (SSH)"

# Add inbound rule for HTTP (port 80)
echo "Adding inbound rule for HTTP (port 80)..."
HTTP_RULE_OUTPUT=$(aws ec2 authorize-security-group-ingress \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 80 \
  --cidr 10.0.0.0/16 2>&1)

check_error "$HTTP_RULE_OUTPUT" "ec2 authorize-security-group-ingress (HTTP)"

echo "Security group configured with SSH and HTTP access from 10.0.0.0/16 network."
echo "Note: In a production environment, you should restrict access to specific IP ranges."

# Step 4: Get the latest Amazon Linux 2 AMI ID
# Note: In a real scenario, you would use the AMI ID from a marketplace product
echo "Getting the latest Amazon Linux 2 AMI ID..."
AMI_OUTPUT=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text 2>&1)

check_error "$AMI_OUTPUT" "ec2 describe-images"

AMI_ID=$AMI_OUTPUT
echo "Using AMI ID: $AMI_ID"
echo "Note: In a real marketplace scenario, you would use the AMI ID from your subscribed product."

# Step 5: Launch an EC2 instance
echo "Launching EC2 instance with the AMI..."
INSTANCE_OUTPUT=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=tutorial,Value=marketplace-buyer-gs}]' 2>&1)

check_error "$INSTANCE_OUTPUT" "ec2 run-instances"

# Extract instance ID
INSTANCE_ID=$(echo "$INSTANCE_OUTPUT" | grep -o '"InstanceId": "[^"]*' | head -1 | cut -d'"' -f4)
echo "Instance launched with ID: $INSTANCE_ID"

# Wait for the instance to be running
echo "Waiting for instance to be in running state..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
echo "Instance is now running."

# Step 6: Get instance details
echo "Getting instance details..."
INSTANCE_DETAILS=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].[InstanceId,State.Name,PublicDnsName]" \
  --output text 2>&1)

check_error "$INSTANCE_DETAILS" "ec2 describe-instances"

echo "Instance details:"
echo "$INSTANCE_DETAILS"

# Display summary of created resources
echo ""
echo "==================================================="
echo "RESOURCE SUMMARY"
echo "==================================================="
echo "Key Pair: $KEY_NAME"
echo "Security Group: $SECURITY_GROUP_NAME (ID: $SECURITY_GROUP_ID)"
echo "EC2 Instance: $INSTANCE_ID"
echo ""
echo "To connect to your instance (once it's fully initialized):"
echo "ssh -i ${KEY_NAME}.pem ec2-user@<public-dns-name>"
echo "Replace <public-dns-name> with the PublicDnsName from the instance details above."
echo ""

# Ask user if they want to clean up resources
echo "==================================================="
echo "CLEANUP CONFIRMATION"
echo "==================================================="
if [ -t 0 ]; then
    read -rp "Do you want to clean up all created resources? (y/n): " CLEANUP_CHOICE
else
    CLEANUP_CHOICE=y
fi

if [[ $CLEANUP_CHOICE =~ ^[Yy]$ ]]; then
    cleanup_resources
else
    echo ""
    echo "Resources have not been cleaned up. You can manually clean them up later with:"
    echo "1. Terminate the EC2 instance: aws ec2 terminate-instances --instance-ids $INSTANCE_ID"
    echo "2. Delete the security group: aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID"
    echo "3. Delete the key pair: aws ec2 delete-key-pair --key-name $KEY_NAME"
    echo ""
fi

echo "Script completed. See $LOG_FILE for the complete log."