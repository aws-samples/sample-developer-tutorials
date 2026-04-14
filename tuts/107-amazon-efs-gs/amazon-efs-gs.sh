#!/bin/bash
# Tutorial: Create an Amazon EFS file system
# Source: https://docs.aws.amazon.com/efs/latest/ug/getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/efs-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(openssl rand -hex 4)
FS_TOKEN="tut-efs-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    if [ -n "$FS_ID" ]; then
        # Delete mount targets first
        for MT_ID in $(aws efs describe-mount-targets --file-system-id "$FS_ID" \
            --query 'MountTargets[].MountTargetId' --output text 2>/dev/null); do
            aws efs delete-mount-target --mount-target-id "$MT_ID" 2>/dev/null
            echo "  Deleted mount target $MT_ID"
        done
        # Wait for mount targets to be deleted
        for i in $(seq 1 12); do
            MT_COUNT=$(aws efs describe-mount-targets --file-system-id "$FS_ID" \
                --query 'MountTargets | length(@)' --output text 2>/dev/null || echo "0")
            [ "$MT_COUNT" = "0" ] && break
            sleep 10
        done
        aws efs delete-file-system --file-system-id "$FS_ID" 2>/dev/null && \
            echo "  Deleted file system $FS_ID"
    fi
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a file system
echo "Step 1: Creating EFS file system"
FS_ID=$(aws efs create-file-system --creation-token "$FS_TOKEN" \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --encrypted \
    --tags Key=Name,Value="tutorial-efs-${RANDOM_ID}" \
    --query 'FileSystemId' --output text)
echo "  File system ID: $FS_ID"

# Step 2: Wait for file system to be available
echo "Step 2: Waiting for file system to be available..."
for i in $(seq 1 15); do
    STATE=$(aws efs describe-file-systems --file-system-id "$FS_ID" \
        --query 'FileSystems[0].LifeCycleState' --output text)
    echo "  State: $STATE"
    [ "$STATE" = "available" ] && break
    sleep 5
done

# Step 3: Describe the file system
echo "Step 3: File system details"
aws efs describe-file-systems --file-system-id "$FS_ID" \
    --query 'FileSystems[0].{Id:FileSystemId,State:LifeCycleState,Encrypted:Encrypted,Performance:PerformanceMode,Size:SizeInBytes.Value}' --output table

# Step 4: Create a mount target
echo "Step 4: Creating mount target"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)
echo "  VPC: $VPC_ID, Subnet: $SUBNET_ID"

MT_ID=$(aws efs create-mount-target --file-system-id "$FS_ID" --subnet-id "$SUBNET_ID" \
    --query 'MountTargetId' --output text)
echo "  Mount target: $MT_ID"

# Step 5: Wait for mount target
echo "Step 5: Waiting for mount target to be available..."
for i in $(seq 1 15); do
    MT_STATE=$(aws efs describe-mount-targets --mount-target-id "$MT_ID" \
        --query 'MountTargets[0].LifeCycleState' --output text)
    echo "  State: $MT_STATE"
    [ "$MT_STATE" = "available" ] && break
    sleep 10
done

# Step 6: Describe mount targets
echo "Step 6: Mount target details"
aws efs describe-mount-targets --file-system-id "$FS_ID" \
    --query 'MountTargets[].{Id:MountTargetId,Subnet:SubnetId,State:LifeCycleState,IP:IpAddress}' --output table

# Step 7: Set lifecycle policy
echo "Step 7: Setting lifecycle policy (move to IA after 30 days)"
aws efs put-lifecycle-configuration --file-system-id "$FS_ID" \
    --lifecycle-policies "[{\"TransitionToIA\":\"AFTER_30_DAYS\"}]" > /dev/null
aws efs describe-lifecycle-configuration --file-system-id "$FS_ID" \
    --query 'LifecyclePolicies' --output table

echo ""
echo "Tutorial complete."
echo "To mount: sudo mount -t nfs4 $FS_ID.efs.$REGION.amazonaws.com:/ /mnt/efs"
echo ""
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Resources left running. EFS charges per GB stored."
    echo "Manual cleanup:"
    echo "  aws efs delete-mount-target --mount-target-id $MT_ID"
    echo "  sleep 60"
    echo "  aws efs delete-file-system --file-system-id $FS_ID"
fi
