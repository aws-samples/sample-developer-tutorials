#!/bin/bash
# Tutorial: Create an Auto Scaling group with a launch template
# Source: https://docs.aws.amazon.com/autoscaling/ec2/userguide/get-started-with-ec2-auto-scaling.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/autoscaling-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
LT_NAME="tut-lt-${RANDOM_ID}"
ASG_NAME="tut-asg-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "$ASG_NAME" \
        --force-delete > /dev/null 2>&1 && echo "  Deleting ASG $ASG_NAME (instances terminating)..."
    # Wait for ASG to be deleted
    for i in $(seq 1 30); do
        aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" \
            --query 'AutoScalingGroups[0].AutoScalingGroupName' --output text 2>/dev/null | grep -q "$ASG_NAME" || break
        sleep 10
    done
    echo "  ASG deleted"
    aws ec2 delete-launch-template --launch-template-name "$LT_NAME" > /dev/null 2>&1 && \
        echo "  Deleted launch template $LT_NAME"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Get the latest Amazon Linux 2023 AMI
echo "Step 1: Finding latest Amazon Linux 2023 AMI"
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-2023*-x86_64" "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)
echo "  AMI: $AMI_ID"

# Step 2: Create a launch template
echo "Step 2: Creating launch template: $LT_NAME"
LT_ID=$(aws ec2 create-launch-template --launch-template-name "$LT_NAME" \
    --launch-template-data "{\"ImageId\":\"$AMI_ID\",\"InstanceType\":\"t2.micro\"}" \
    --query 'LaunchTemplate.LaunchTemplateId' --output text)
echo "  Launch template: $LT_ID"

# Step 3: Get availability zones
echo "Step 3: Getting availability zones"
AZS=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[:2].ZoneName' --output text)
echo "  Using: $AZS"

# Step 4: Create Auto Scaling group
echo "Step 4: Creating Auto Scaling group: $ASG_NAME"
aws autoscaling create-auto-scaling-group --auto-scaling-group-name "$ASG_NAME" \
    --launch-template "LaunchTemplateId=$LT_ID,Version=\$Latest" \
    --min-size 1 --max-size 3 --desired-capacity 1 \
    --availability-zones $AZS
echo "  ASG created (desired: 1, min: 1, max: 3)"

# Step 5: Wait for instance to launch
echo "Step 5: Waiting for instance to launch..."
for i in $(seq 1 12); do
    INSTANCE_COUNT=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names "$ASG_NAME" \
        --query 'AutoScalingGroups[0].Instances | length(@)' --output text 2>/dev/null || echo "0")
    if [ "$INSTANCE_COUNT" -gt 0 ] 2>/dev/null; then
        echo "  $INSTANCE_COUNT instance(s) running"
        aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" \
            --query 'AutoScalingGroups[0].Instances[].{Id:InstanceId,AZ:AvailabilityZone,Health:HealthStatus,Lifecycle:LifecycleState}' --output table
        break
    fi
    sleep 10
done

# Step 6: Describe the group
echo "Step 6: Auto Scaling group details"
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].{Name:AutoScalingGroupName,Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Instances:Instances|length(@)}' --output table

echo ""
echo "Tutorial complete."
echo "Note: EC2 instances are running and will incur charges until cleaned up."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Resources left running. Instances will incur charges."
    echo "Manual cleanup:"
    echo "  aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $ASG_NAME --force-delete"
    echo "  aws ec2 delete-launch-template --launch-template-name $LT_NAME"
fi
