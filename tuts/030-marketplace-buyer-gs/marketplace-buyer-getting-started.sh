#!/bin/bash

# AWS Marketplace Buyer Getting Started Script
# This script demonstrates how to search for products in AWS Marketplace,
# launch an EC2 instance with a product AMI, and manage subscriptions.

set -euo pipefail

# Setup logging
LOG_FILE="marketplace-tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Security: Set secure umask
umask 0077

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

# Validate AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed or not in PATH"
    exit 1
fi

# Validate jq is installed for secure JSON parsing
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is not installed. Please install jq for secure JSON parsing"
    exit 1
fi

# Validate AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS credentials are not configured or invalid"
    exit 1
fi

# Function to clean up resources
cleanup_resources() {
    echo ""
    echo "==================================================="
    echo "CLEANING UP RESOURCES"
    echo "==================================================="
    
    if [ -n "${INSTANCE_ID:-}" ]; then
        echo "Terminating EC2 instance: $INSTANCE_ID"
        aws ec2 terminate-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --output json > /dev/null 2>&1 || true
        
        echo "Waiting for instance to terminate..."
        aws ec2 wait instance-terminated --region "$REGION" --instance-ids "$INSTANCE_ID" 2>/dev/null || true
        echo "Instance terminated successfully."
    fi
    
    if [ -n "${SECURITY_GROUP_ID:-}" ]; then
        # Wait a moment for instance termination to fully process
        sleep 5
        echo "Deleting security group: $SECURITY_GROUP_ID"
        aws ec2 delete-security-group --region "$REGION" --group-id "$SECURITY_GROUP_ID" --output json > /dev/null 2>&1 || true
        echo "Security group deleted."
    fi
    
    if [ -n "${KEY_NAME:-}" ]; then
        echo "Deleting key pair: $KEY_NAME"
        aws ec2 delete-key-pair --region "$REGION" --key-name "$KEY_NAME" --output json > /dev/null 2>&1 || true
        
        # Remove the local key file if it exists
        if [ -f "${KEY_NAME}.pem" ]; then
            shred -vfz -n 3 "${KEY_NAME}.pem" 2>/dev/null || rm -f "${KEY_NAME}.pem"
            echo "Local key file securely deleted."
        fi
    fi
    
    echo "Cleanup completed."
}

# Set up trap to ensure cleanup on script exit
trap cleanup_resources EXIT

# Generate random identifier for resource names using cryptographic source
RANDOM_ID=$(openssl rand -hex 6)
KEY_NAME="marketplace-key-${RANDOM_ID}"
SECURITY_GROUP_NAME="marketplace-sg-${RANDOM_ID}"

# Initialize variables to track created resources
INSTANCE_ID=""
SECURITY_GROUP_ID=""
REGION="${AWS_REGION:-$(aws configure get region || echo 'us-east-1')}"

# Validate region
if [ -z "$REGION" ]; then
    echo "ERROR: AWS region is not set. Please configure AWS_REGION or set default region."
    exit 1
fi

echo "Using AWS Region: $REGION"
echo ""

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
aws ec2 create-key-pair \
  --region "$REGION" \
  --key-name "$KEY_NAME" \
  --query 'KeyMaterial' \
  --output text > "${KEY_NAME}.pem"

# Verify key file was created
if [ ! -f "${KEY_NAME}.pem" ]; then
    echo "ERROR: Key file was not created successfully"
    exit 1
fi

# Set proper permissions for the key file
chmod 400 "${KEY_NAME}.pem"
echo "Key pair created and saved to ${KEY_NAME}.pem"

# Step 3: Create a security group
echo "Creating security group: $SECURITY_GROUP_NAME"
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --region "$REGION" \
  --group-name "$SECURITY_GROUP_NAME" \
  --description "Security group for AWS Marketplace tutorial" \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=project,Value=doc-smith},{Key=tutorial,Value=marketplace-buyer-gs}]' \
  --query 'GroupId' \
  --output text)

if [ -z "$SECURITY_GROUP_ID" ] || [ "$SECURITY_GROUP_ID" == "None" ]; then
    echo "ERROR: Failed to create security group or extract security group ID"
    exit 1
fi

echo "Security group created with ID: $SECURITY_GROUP_ID"

# Add inbound rules in parallel for better performance
echo "Configuring security group rules..."
aws ec2 authorize-security-group-ingress \
  --region "$REGION" \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 10.0.0.0/16 \
  --output json > /dev/null &

aws ec2 authorize-security-group-ingress \
  --region "$REGION" \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 80 \
  --cidr 10.0.0.0/16 \
  --output json > /dev/null &

wait

echo "Security group configured with SSH and HTTP access from 10.0.0.0/16 network."
echo "Note: In a production environment, you should restrict access to specific IP ranges."

# Step 4: Get the latest Amazon Linux 2 AMI ID
echo "Getting the latest Amazon Linux 2 AMI ID..."
AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text)

if [ -z "$AMI_ID" ] || [ "$AMI_ID" == "None" ]; then
    echo "ERROR: Failed to retrieve AMI ID"
    exit 1
fi

echo "Using AMI ID: $AMI_ID"
echo "Note: In a real marketplace scenario, you would use the AMI ID from your subscribed product."

# Step 5: Launch an EC2 instance
echo "Launching EC2 instance with the AMI..."
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --count 1 \
  --monitoring Enabled=true \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=project,Value=doc-smith},{Key=tutorial,Value=marketplace-buyer-gs}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
    echo "ERROR: Failed to launch instance or extract instance ID"
    exit 1
fi

echo "Instance launched with ID: $INSTANCE_ID"

# Wait for the instance to be running
echo "Waiting for instance to be in running state..."
aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"
echo "Instance is now running."

# Step 6: Get instance details
echo "Getting instance details..."
INSTANCE_DETAILS=$(aws ec2 describe-instances \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].[InstanceId,State.Name,PublicDnsName]" \
  --output text)

if [ -z "$INSTANCE_DETAILS" ]; then
    echo "ERROR: Failed to retrieve instance details"
    exit 1
fi

echo "Instance details:"
echo "$INSTANCE_DETAILS"

# Display summary of created resources
echo ""
echo "==================================================="
echo "RESOURCE SUMMARY"
echo "==================================================="
echo "Region: $REGION"
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
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ $CLEANUP_CHOICE =~ ^[Yy]$ ]]; then
    cleanup_resources
    trap - EXIT
else
    echo ""
    echo "Resources have not been cleaned up. You can manually clean them up later with:"
    echo "1. Terminate the EC2 instance: aws ec2 terminate-instances --region $REGION --instance-ids $INSTANCE_ID"
    echo "2. Delete the security group: aws ec2 delete-security-group --region $REGION --group-id $SECURITY_GROUP_ID"
    echo "3. Delete the key pair: aws ec2 delete-key-pair --region $REGION --key-name $KEY_NAME"
    echo "4. Securely delete key file: shred -vfz -n 3 ${KEY_NAME}.pem"
    echo ""
    trap - EXIT
fi

echo "Script completed. See $LOG_FILE for the complete log."