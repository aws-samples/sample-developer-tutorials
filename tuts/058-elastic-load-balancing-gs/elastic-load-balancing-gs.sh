#!/bin/bash

# Elastic Load Balancing Getting Started Script - v2
# This script creates an Application Load Balancer with HTTP listener and target group

# Set up logging
LOG_FILE="elb-script-v2.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Elastic Load Balancing setup script at $(date)"
echo "All commands and outputs will be logged to $LOG_FILE"

# Function to handle errors
handle_error() {
    echo "ERROR: $1"
    echo "Attempting to clean up resources..."
    cleanup_resources
    exit 1
}

# Function to check command success
check_command() {
    if echo "$1" | grep -i "error" > /dev/null; then
        handle_error "$1"
    fi
}

# Function to clean up resources
cleanup_resources() {
    echo "Cleaning up resources in reverse order..."
    
    if [ -n "$LISTENER_ARN" ]; then
        echo "Deleting listener: $LISTENER_ARN"
        aws elbv2 delete-listener --listener-arn "$LISTENER_ARN"
    fi
    
    if [ -n "$LOAD_BALANCER_ARN" ]; then
        echo "Deleting load balancer: $LOAD_BALANCER_ARN"
        aws elbv2 delete-load-balancer --load-balancer-arn "$LOAD_BALANCER_ARN"
        
        # Wait for load balancer to be deleted before deleting target group
        echo "Waiting for load balancer to be deleted..."
        aws elbv2 wait load-balancers-deleted --load-balancer-arns "$LOAD_BALANCER_ARN"
    fi
    
    if [ -n "$TARGET_GROUP_ARN" ]; then
        echo "Deleting target group: $TARGET_GROUP_ARN"
        aws elbv2 delete-target-group --target-group-arn "$TARGET_GROUP_ARN"
    fi
    
    # Add a delay before attempting to delete the security group
    # to ensure all ELB resources are fully deleted
    if [ -n "$SECURITY_GROUP_ID" ]; then
        echo "Waiting 30 seconds before deleting security group to ensure all dependencies are removed..."
        sleep 30
        
        echo "Deleting security group: $SECURITY_GROUP_ID"
        SG_DELETE_OUTPUT=$(aws ec2 delete-security-group --group-id "$SECURITY_GROUP_ID" 2>&1)
        
        # If there's still a dependency issue, retry a few times
        RETRY_COUNT=0
        MAX_RETRIES=5
        while echo "$SG_DELETE_OUTPUT" | grep -i "DependencyViolation" > /dev/null && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
            RETRY_COUNT=$((RETRY_COUNT+1))
            echo "Security group still has dependencies. Retrying in 30 seconds... (Attempt $RETRY_COUNT of $MAX_RETRIES)"
            sleep 30
            SG_DELETE_OUTPUT=$(aws ec2 delete-security-group --group-id "$SECURITY_GROUP_ID" 2>&1)
        done
        
        if echo "$SG_DELETE_OUTPUT" | grep -i "error" > /dev/null; then
            echo "WARNING: Could not delete security group: $SECURITY_GROUP_ID"
            echo "You may need to delete it manually using: aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID"
        else
            echo "Security group deleted successfully."
        fi
    fi
}

# Generate a random identifier for resource names
RANDOM_ID=$(openssl rand -hex 4)
RESOURCE_PREFIX="elb-demo-${RANDOM_ID}"

# Step 1: Verify AWS CLI support for Elastic Load Balancing
echo "Verifying AWS CLI support for Elastic Load Balancing..."
aws elbv2 help > /dev/null 2>&1
if [ $? -ne 0 ]; then
    handle_error "AWS CLI does not support elbv2 commands. Please update your AWS CLI."
fi

# Step 2: Get VPC ID and subnet information
echo "Retrieving VPC information..."
VPC_INFO=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
check_command "$VPC_INFO"
VPC_ID=$VPC_INFO
echo "Using VPC: $VPC_ID"

# Get two subnets from different Availability Zones
echo "Retrieving subnet information..."
SUBNET_INFO=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[0:2].SubnetId" --output text)
check_command "$SUBNET_INFO"

# Convert space-separated list to array
read -r -a SUBNETS <<< "$SUBNET_INFO"
if [ ${#SUBNETS[@]} -lt 2 ]; then
    handle_error "Need at least 2 subnets in different Availability Zones. Found: ${#SUBNETS[@]}"
fi

echo "Using subnets: ${SUBNETS[0]} and ${SUBNETS[1]}"

# Step 3: Create a security group for the load balancer
echo "Creating security group for the load balancer..."
SG_INFO=$(aws ec2 create-security-group \
    --group-name "${RESOURCE_PREFIX}-sg" \
    --description "Security group for ELB demo" \
    --vpc-id "$VPC_ID" \
    --tag-specifications 'ResourceType=security-group,Tags=[{Key=tutorial,Value=elastic-load-balancing-gs}]' \
    --query "GroupId" --output text)
check_command "$SG_INFO"
SECURITY_GROUP_ID=$SG_INFO
echo "Created security group: $SECURITY_GROUP_ID"

# Add inbound rule to allow HTTP traffic
echo "Adding inbound rule to allow HTTP traffic..."
aws ec2 authorize-security-group-ingress \
    --group-id "$SECURITY_GROUP_ID" \
    --protocol tcp \
    --port 80 \
    --cidr "0.0.0.0/0" > /dev/null
# Note: In production, you should restrict the CIDR range to specific IP addresses

# Step 4: Create the load balancer
echo "Creating Application Load Balancer..."
LB_INFO=$(aws elbv2 create-load-balancer \
    --name "${RESOURCE_PREFIX}-lb" \
    --subnets "${SUBNETS[0]}" "${SUBNETS[1]}" \
    --security-groups "$SECURITY_GROUP_ID" \
    --tags Key=tutorial,Value=elastic-load-balancing-gs \
    --query "LoadBalancers[0].LoadBalancerArn" --output text)
check_command "$LB_INFO"
LOAD_BALANCER_ARN=$LB_INFO
echo "Created load balancer: $LOAD_BALANCER_ARN"

# Wait for the load balancer to be active
echo "Waiting for load balancer to become active..."
aws elbv2 wait load-balancer-available --load-balancer-arns "$LOAD_BALANCER_ARN"

# Step 5: Create a target group
echo "Creating target group..."
TG_INFO=$(aws elbv2 create-target-group \
    --name "${RESOURCE_PREFIX}-targets" \
    --protocol HTTP \
    --port 80 \
    --vpc-id "$VPC_ID" \
    --target-type instance \
    --tags Key=tutorial,Value=elastic-load-balancing-gs \
    --query "TargetGroups[0].TargetGroupArn" --output text)
check_command "$TG_INFO"
TARGET_GROUP_ARN=$TG_INFO
echo "Created target group: $TARGET_GROUP_ARN"

# Step 6: Find EC2 instances to register as targets
echo "Looking for available EC2 instances to register as targets..."
INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].InstanceId" --output text)
check_command "$INSTANCES"

# Convert space-separated list to array
read -r -a INSTANCE_IDS <<< "$INSTANCES"

if [ ${#INSTANCE_IDS[@]} -eq 0 ]; then
    echo "No running instances found in VPC $VPC_ID."
    echo "You will need to register targets manually after launching instances."
else
    # Step 7: Register targets with the target group (up to 2 instances)
    echo "Registering targets with the target group..."
    TARGET_ARGS=""
    for i in "${!INSTANCE_IDS[@]}"; do
        if [ "$i" -lt 2 ]; then  # Register up to 2 instances
            TARGET_ARGS="$TARGET_ARGS Id=${INSTANCE_IDS[$i]} "
        fi
    done
    
    if [ -n "$TARGET_ARGS" ]; then
        aws elbv2 register-targets \
            --target-group-arn "$TARGET_GROUP_ARN" \
            --targets $TARGET_ARGS
        echo "Registered instances: $TARGET_ARGS"
    fi
fi

# Step 8: Create a listener
echo "Creating HTTP listener..."
LISTENER_INFO=$(aws elbv2 create-listener \
    --load-balancer-arn "$LOAD_BALANCER_ARN" \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN" \
    --tags Key=tutorial,Value=elastic-load-balancing-gs \
    --query "Listeners[0].ListenerArn" --output text)
check_command "$LISTENER_INFO"
LISTENER_ARN=$LISTENER_INFO
echo "Created listener: $LISTENER_ARN"

# Step 9: Verify target health
echo "Verifying target health..."
aws elbv2 describe-target-health --target-group-arn "$TARGET_GROUP_ARN"

# Display load balancer DNS name
LB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns "$LOAD_BALANCER_ARN" \
    --query "LoadBalancers[0].DNSName" --output text)
check_command "$LB_DNS"

echo ""
echo "=============================================="
echo "SETUP COMPLETE"
echo "=============================================="
echo "Load Balancer DNS Name: $LB_DNS"
echo ""
echo "Resources created:"
echo "- Load Balancer: $LOAD_BALANCER_ARN"
echo "- Target Group: $TARGET_GROUP_ARN"
echo "- Listener: $LISTENER_ARN"
echo "- Security Group: $SECURITY_GROUP_ID"
echo ""

# Ask user if they want to clean up resources
echo "=============================================="
echo "CLEANUP CONFIRMATION"
echo "=============================================="
echo "Do you want to clean up all created resources? (y/n): "
if [ -t 0 ]; then
    read -r CLEANUP_CHOICE
else
    CLEANUP_CHOICE=n
fi

if [[ "$CLEANUP_CHOICE" =~ ^[Yy] ]]; then
    echo "Starting cleanup process..."
    cleanup_resources
    echo "Cleanup completed."
else
    echo "Resources have been preserved."
    echo "To clean up later, run the following commands:"
    echo "aws elbv2 delete-listener --listener-arn $LISTENER_ARN"
    echo "aws elbv2 delete-load-balancer --load-balancer-arn $LOAD_BALANCER_ARN"
    echo "aws elbv2 wait load-balancers-deleted --load-balancer-arns $LOAD_BALANCER_ARN"
    echo "aws elbv2 delete-target-group --target-group-arn $TARGET_GROUP_ARN"
    echo "aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID"
fi

echo "Script completed at $(date)"