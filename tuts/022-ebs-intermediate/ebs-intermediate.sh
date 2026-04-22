#!/bin/bash

# Script for EBS operations: encryption, snapshots, and volume initialization
# This script demonstrates:
# 1. Enabling EBS encryption by default
# 2. Creating an EBS snapshot
# 3. Creating a volume from a snapshot

# Setup logging
LOG_FILE="ebs-operations-v2.log"
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

# Function to cleanup resources
cleanup_resources() {
    echo "Attempting to clean up resources..."
    
    if [ -n "$NEW_VOLUME_ID" ]; then
        echo "Checking if new volume is attached..."
        ATTACHMENT_STATE=$(aws ec2 describe-volumes --volume-ids "$NEW_VOLUME_ID" --query 'Volumes[0].Attachments[0].State' --output text 2>/dev/null)
        
        if [ "$ATTACHMENT_STATE" == "attached" ]; then
            echo "Detaching new volume $NEW_VOLUME_ID..."
            aws ec2 detach-volume --volume-id "$NEW_VOLUME_ID"
            echo "Waiting for volume to detach..."
            aws ec2 wait volume-available --volume-ids "$NEW_VOLUME_ID"
        fi
        
        echo "Deleting new volume $NEW_VOLUME_ID..."
        aws ec2 delete-volume --volume-id "$NEW_VOLUME_ID"
    fi
    
    if [ -n "$VOLUME_ID" ]; then
        echo "Checking if original volume is attached..."
        ATTACHMENT_STATE=$(aws ec2 describe-volumes --volume-ids "$VOLUME_ID" --query 'Volumes[0].Attachments[0].State' --output text 2>/dev/null)
        
        if [ "$ATTACHMENT_STATE" == "attached" ]; then
            echo "Detaching original volume $VOLUME_ID..."
            aws ec2 detach-volume --volume-id "$VOLUME_ID"
            echo "Waiting for volume to detach..."
            aws ec2 wait volume-available --volume-ids "$VOLUME_ID"
        fi
        
        echo "Deleting original volume $VOLUME_ID..."
        aws ec2 delete-volume --volume-id "$VOLUME_ID"
    fi
    
    if [ -n "$SNAPSHOT_ID" ]; then
        echo "Deleting snapshot $SNAPSHOT_ID..."
        aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID"
    fi
    
    if [ "$ENCRYPTION_MODIFIED" = true ]; then
        echo "Restoring original encryption setting..."
        if [ "$ORIGINAL_ENCRYPTION" = "False" ]; then
            aws ec2 disable-ebs-encryption-by-default
        else
            aws ec2 enable-ebs-encryption-by-default
        fi
    fi
    
    echo "Cleanup completed."
}

# Track created resources
VOLUME_ID=""
NEW_VOLUME_ID=""
SNAPSHOT_ID=""
ENCRYPTION_MODIFIED=false
ORIGINAL_ENCRYPTION=""

# Get the current AWS region
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    AWS_REGION="us-east-1"
    echo "No region found in AWS config. Using default: $AWS_REGION"
fi

# Get availability zones in the region
AVAILABILITY_ZONE=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].ZoneName' --output text)
check_status "Getting availability zone"
echo "Using availability zone: $AVAILABILITY_ZONE"

# Step 1: Check and enable EBS encryption by default
echo "Step 1: Checking current EBS encryption by default setting..."
ORIGINAL_ENCRYPTION=$(aws ec2 get-ebs-encryption-by-default --query 'EbsEncryptionByDefault' --output text)
check_status "Checking encryption status"
echo "Current encryption by default setting: $ORIGINAL_ENCRYPTION"

if [ "$ORIGINAL_ENCRYPTION" = "False" ]; then
    echo "Enabling EBS encryption by default..."
    aws ec2 enable-ebs-encryption-by-default
    check_status "Enabling encryption by default"
    ENCRYPTION_MODIFIED=true
    
    # Verify encryption is enabled
    ENCRYPTION_STATUS=$(aws ec2 get-ebs-encryption-by-default --query 'EbsEncryptionByDefault' --output text)
    check_status "Verifying encryption status"
    echo "Updated encryption by default setting: $ENCRYPTION_STATUS"
else
    echo "EBS encryption by default is already enabled."
fi

# Check the default KMS key
echo "Checking default KMS key for EBS encryption..."
KMS_KEY=$(aws ec2 get-ebs-default-kms-key-id --query 'KmsKeyId' --output text)
check_status "Getting default KMS key"
echo "Default KMS key: $KMS_KEY"

# Step 2: Create a test volume for snapshot
echo "Step 2: Creating a test volume..."
VOLUME_ID=$(aws ec2 create-volume --availability-zone "$AVAILABILITY_ZONE" --size 1 --volume-type gp3 --tag-specifications 'ResourceType=volume,Tags=[{Key=tutorial,Value=ebs-intermediate}]' --query 'VolumeId' --output text)
check_status "Creating test volume"
echo "Created test volume: $VOLUME_ID"

# Wait for volume to become available
echo "Waiting for volume to become available..."
aws ec2 wait volume-available --volume-ids "$VOLUME_ID"
check_status "Waiting for volume"

# Step 3: Create a snapshot of the volume
echo "Step 3: Creating snapshot of the volume..."
SNAPSHOT_ID=$(aws ec2 create-snapshot --volume-id "$VOLUME_ID" --description "Snapshot for EBS tutorial" --tag-specifications 'ResourceType=snapshot,Tags=[{Key=tutorial,Value=ebs-intermediate}]' --query 'SnapshotId' --output text)
check_status "Creating snapshot"
echo "Created snapshot: $SNAPSHOT_ID"

# Wait for snapshot to complete
echo "Waiting for snapshot to complete (this may take several minutes)..."
aws ec2 wait snapshot-completed --snapshot-ids "$SNAPSHOT_ID"
check_status "Waiting for snapshot"
echo "Snapshot completed."

# Step 4: Create a new volume from the snapshot
echo "Step 4: Creating a new volume from the snapshot..."
NEW_VOLUME_ID=$(aws ec2 create-volume --snapshot-id "$SNAPSHOT_ID" --availability-zone "$AVAILABILITY_ZONE" --volume-type gp3 --tag-specifications 'ResourceType=volume,Tags=[{Key=tutorial,Value=ebs-intermediate}]' --query 'VolumeId' --output text)
check_status "Creating new volume from snapshot"
echo "Created new volume from snapshot: $NEW_VOLUME_ID"

# Wait for new volume to become available
echo "Waiting for new volume to become available..."
aws ec2 wait volume-available --volume-ids "$NEW_VOLUME_ID"
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
if [ -t 0 ]; then
    read -rp "Do you want to clean up all created resources? (y/n): " CLEANUP_CHOICE
else
    CLEANUP_CHOICE="y"
fi

if [[ "$CLEANUP_CHOICE" =~ ^[Yy] ]]; then
    echo "Starting cleanup process..."
    
    # Delete the new volume
    echo "Deleting new volume $NEW_VOLUME_ID..."
    aws ec2 delete-volume --volume-id "$NEW_VOLUME_ID"
    check_status "Deleting new volume"
    
    # Delete the original volume
    echo "Deleting original volume $VOLUME_ID..."
    aws ec2 delete-volume --volume-id "$VOLUME_ID"
    check_status "Deleting original volume"
    
    # Delete the snapshot
    echo "Deleting snapshot $SNAPSHOT_ID..."
    aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID"
    check_status "Deleting snapshot"
    
    # Restore original encryption setting if modified
    if [ "$ENCRYPTION_MODIFIED" = true ]; then
        echo "Restoring original encryption setting..."
        if [ "$ORIGINAL_ENCRYPTION" = "False" ]; then
            aws ec2 disable-ebs-encryption-by-default
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

echo "Script completed at $(date)"