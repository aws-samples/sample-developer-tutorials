#!/bin/bash

# Script for EBS operations: encryption, snapshots, and volume initialization
# This script demonstrates:
# 1. Enabling EBS encryption by default
# 2. Creating an EBS snapshot
# 3. Creating a volume from a snapshot

set -euo pipefail

# Security: Restrict file permissions
umask 0077

# Setup logging with secure file permissions
LOG_FILE="ebs-operations-v2.log"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting EBS operations script at $(date)"
echo "All operations will be logged to $LOG_FILE"

# Function to check command status
check_status() {
    if [ $? -ne 0 ]; then
        echo "ERROR: $1 failed. Exiting."
        cleanup_resources
        exit 1
    fi
}

# Function to validate AWS CLI output
validate_output() {
    local output="$1"
    local field_name="$2"
    
    if [ -z "$output" ] || [ "$output" = "None" ]; then
        echo "ERROR: Failed to retrieve $field_name"
        exit 1
    fi
    echo "$output"
}

# Function to cleanup resources
cleanup_resources() {
    echo "Attempting to clean up resources..."
    
    if [ -n "${NEW_VOLUME_ID:-}" ]; then
        echo "Checking if new volume is attached..."
        ATTACHMENT_STATE=$(aws ec2 describe-volumes --volume-ids "$NEW_VOLUME_ID" --region "$AWS_REGION" --query 'Volumes[0].Attachments[0].State' --output text 2>/dev/null || echo "")
        
        if [ "$ATTACHMENT_STATE" = "attached" ]; then
            echo "Detaching new volume $NEW_VOLUME_ID..."
            aws ec2 detach-volume --volume-id "$NEW_VOLUME_ID" --region "$AWS_REGION" || true
            echo "Waiting for volume to detach..."
            aws ec2 wait volume-available --region "$AWS_REGION" --volume-ids "$NEW_VOLUME_ID" || true
        fi
        
        echo "Deleting new volume $NEW_VOLUME_ID..."
        aws ec2 delete-volume --volume-id "$NEW_VOLUME_ID" --region "$AWS_REGION" || true
    fi
    
    if [ -n "${VOLUME_ID:-}" ]; then
        echo "Checking if original volume is attached..."
        ATTACHMENT_STATE=$(aws ec2 describe-volumes --volume-ids "$VOLUME_ID" --region "$AWS_REGION" --query 'Volumes[0].Attachments[0].State' --output text 2>/dev/null || echo "")
        
        if [ "$ATTACHMENT_STATE" = "attached" ]; then
            echo "Detaching original volume $VOLUME_ID..."
            aws ec2 detach-volume --volume-id "$VOLUME_ID" --region "$AWS_REGION" || true
            echo "Waiting for volume to detach..."
            aws ec2 wait volume-available --region "$AWS_REGION" --volume-ids "$VOLUME_ID" || true
        fi
        
        echo "Deleting original volume $VOLUME_ID..."
        aws ec2 delete-volume --volume-id "$VOLUME_ID" --region "$AWS_REGION" || true
    fi
    
    if [ -n "${SNAPSHOT_ID:-}" ]; then
        echo "Deleting snapshot $SNAPSHOT_ID..."
        aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID" --region "$AWS_REGION" || true
    fi
    
    if [ "${ENCRYPTION_MODIFIED:-false}" = true ]; then
        echo "Restoring original encryption setting..."
        if [ "${ORIGINAL_ENCRYPTION:-}" = "False" ]; then
            aws ec2 disable-ebs-encryption-by-default --region "$AWS_REGION" || true
        else
            aws ec2 enable-ebs-encryption-by-default --region "$AWS_REGION" || true
        fi
    fi
    
    echo "Cleanup completed."
}

# Set trap for cleanup on exit
trap cleanup_resources EXIT

# Track created resources
VOLUME_ID=""
NEW_VOLUME_ID=""
SNAPSHOT_ID=""
ENCRYPTION_MODIFIED=false
ORIGINAL_ENCRYPTION=""
AWS_REGION=""

# Validate AWS CLI is installed and authenticated
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed. Please install it first."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS CLI authentication failed. Please configure credentials."
    exit 1
fi

# Get the current AWS region
AWS_REGION=$(aws configure get region 2>/dev/null || echo "")
if [ -z "$AWS_REGION" ]; then
    AWS_REGION="us-east-1"
    echo "WARNING: No region found in AWS config. Using default: $AWS_REGION"
fi
echo "Using AWS region: $AWS_REGION"

# Validate region format (basic check)
if ! [[ "$AWS_REGION" =~ ^[a-z]{2}-[a-z]+-[0-9]{1}$ ]]; then
    echo "WARNING: Region format appears invalid: $AWS_REGION"
fi

# Get availability zones in the region
AVAILABILITY_ZONE=$(aws ec2 describe-availability-zones --region "$AWS_REGION" --query 'AvailabilityZones[0].ZoneName' --output text 2>/dev/null)
check_status "Getting availability zone"
AVAILABILITY_ZONE=$(validate_output "$AVAILABILITY_ZONE" "availability zone")
echo "Using availability zone: $AVAILABILITY_ZONE"

# Step 1: Check and enable EBS encryption by default
echo "Step 1: Checking current EBS encryption by default setting..."
ORIGINAL_ENCRYPTION=$(aws ec2 get-ebs-encryption-by-default --region "$AWS_REGION" --query 'EbsEncryptionByDefault' --output text 2>/dev/null)
check_status "Checking encryption status"
echo "Current encryption by default setting: $ORIGINAL_ENCRYPTION"

if [ "$ORIGINAL_ENCRYPTION" = "False" ]; then
    echo "Enabling EBS encryption by default..."
    aws ec2 enable-ebs-encryption-by-default --region "$AWS_REGION"
    check_status "Enabling encryption by default"
    ENCRYPTION_MODIFIED=true
    
    # Verify encryption is enabled
    ENCRYPTION_STATUS=$(aws ec2 get-ebs-encryption-by-default --region "$AWS_REGION" --query 'EbsEncryptionByDefault' --output text 2>/dev/null)
    check_status "Verifying encryption status"
    echo "Updated encryption by default setting: $ENCRYPTION_STATUS"
else
    echo "EBS encryption by default is already enabled."
fi

# Check the default KMS key
echo "Checking default KMS key for EBS encryption..."
KMS_KEY=$(aws ec2 get-ebs-default-kms-key-id --region "$AWS_REGION" --query 'KmsKeyId' --output text 2>/dev/null)
check_status "Getting default KMS key"
KMS_KEY=$(validate_output "$KMS_KEY" "KMS key")
echo "Default KMS key: $KMS_KEY"

# Step 2: Create a test volume for snapshot
echo "Step 2: Creating a test volume..."
VOLUME_ID=$(aws ec2 create-volume --region "$AWS_REGION" --availability-zone "$AVAILABILITY_ZONE" --size 1 --volume-type gp3 --tag-specifications 'ResourceType=volume,Tags=[{Key=project,Value=doc-smith},{Key=tutorial,Value=ebs-intermediate}]' --query 'VolumeId' --output text 2>/dev/null)
check_status "Creating test volume"
VOLUME_ID=$(validate_output "$VOLUME_ID" "volume ID")
echo "Created test volume: $VOLUME_ID"

# Wait for volume to become available
echo "Waiting for volume to become available..."
aws ec2 wait volume-available --region "$AWS_REGION" --volume-ids "$VOLUME_ID"
check_status "Waiting for volume"

# Step 3: Create a snapshot of the volume
echo "Step 3: Creating snapshot of the volume..."
SNAPSHOT_ID=$(aws ec2 create-snapshot --region "$AWS_REGION" --volume-id "$VOLUME_ID" --description "Snapshot for EBS tutorial" --tag-specifications 'ResourceType=snapshot,Tags=[{Key=project,Value=doc-smith},{Key=tutorial,Value=ebs-intermediate}]' --query 'SnapshotId' --output text 2>/dev/null)
check_status "Creating snapshot"
SNAPSHOT_ID=$(validate_output "$SNAPSHOT_ID" "snapshot ID")
echo "Created snapshot: $SNAPSHOT_ID"

# Wait for snapshot to complete
echo "Waiting for snapshot to complete (this may take several minutes)..."
aws ec2 wait snapshot-completed --region "$AWS_REGION" --snapshot-ids "$SNAPSHOT_ID"
check_status "Waiting for snapshot"
echo "Snapshot completed."

# Step 4: Create a new volume from the snapshot
echo "Step 4: Creating a new volume from the snapshot..."
NEW_VOLUME_ID=$(aws ec2 create-volume --region "$AWS_REGION" --snapshot-id "$SNAPSHOT_ID" --availability-zone "$AVAILABILITY_ZONE" --volume-type gp3 --tag-specifications 'ResourceType=volume,Tags=[{Key=project,Value=doc-smith},{Key=tutorial,Value=ebs-intermediate}]' --query 'VolumeId' --output text 2>/dev/null)
check_status "Creating new volume from snapshot"
NEW_VOLUME_ID=$(validate_output "$NEW_VOLUME_ID" "new volume ID")
echo "Created new volume from snapshot: $NEW_VOLUME_ID"

# Wait for new volume to become available
echo "Waiting for new volume to become available..."
aws ec2 wait volume-available --region "$AWS_REGION" --volume-ids "$NEW_VOLUME_ID"
check_status "Waiting for new volume"

# Display created resources
echo ""
echo "==========================================="
echo "RESOURCES CREATED"
echo "==========================================="
echo "Original Volume: $VOLUME_ID"
echo "Snapshot: $SNAPSHOT_ID"
echo "New Volume: $NEW_VOLUME_ID"
echo "==========================================="

# Prompt for cleanup
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r -t 300 CLEANUP_CHOICE || CLEANUP_CHOICE="n"

# Validate cleanup choice input
if [[ "$CLEANUP_CHOICE" =~ ^[YyNn]$ ]]; then
    if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
        echo "Starting cleanup process..."
        
        # Delete the new volume
        echo "Deleting new volume $NEW_VOLUME_ID..."
        aws ec2 delete-volume --region "$AWS_REGION" --volume-id "$NEW_VOLUME_ID" 2>/dev/null || true
        check_status "Deleting new volume"
        
        # Delete the original volume
        echo "Deleting original volume $VOLUME_ID..."
        aws ec2 delete-volume --region "$AWS_REGION" --volume-id "$VOLUME_ID" 2>/dev/null || true
        check_status "Deleting original volume"
        
        # Delete the snapshot
        echo "Deleting snapshot $SNAPSHOT_ID..."
        aws ec2 delete-snapshot --region "$AWS_REGION" --snapshot-id "$SNAPSHOT_ID" 2>/dev/null || true
        check_status "Deleting snapshot"
        
        # Restore original encryption setting if modified
        if [ "$ENCRYPTION_MODIFIED" = true ]; then
            echo "Restoring original encryption setting..."
            if [ "$ORIGINAL_ENCRYPTION" = "False" ]; then
                aws ec2 disable-ebs-encryption-by-default --region "$AWS_REGION" 2>/dev/null || true
                check_status "Disabling encryption by default"
            fi
        fi
        
        echo "Cleanup completed successfully."
    else
        echo "Skipping cleanup. Resources will remain in your account."
        echo "To clean up manually, delete the following resources:"
        echo "1. Volume: $NEW_VOLUME_ID"
        echo "2. Volume: $VOLUME_ID"
        echo "3. Snapshot: $SNAPSHOT_ID"
        echo "4. Restore encryption setting with: aws ec2 disable-ebs-encryption-by-default (if needed)"
    fi
else
    echo "Invalid input. Skipping cleanup. Resources will remain in your account."
    echo "To clean up manually, delete the following resources:"
    echo "1. Volume: $NEW_VOLUME_ID"
    echo "2. Volume: $VOLUME_ID"
    echo "3. Snapshot: $SNAPSHOT_ID"
fi

echo "Script completed at $(date)"