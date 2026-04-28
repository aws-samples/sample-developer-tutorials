#!/bin/bash

# Elastic Load Balancing Getting Started Script - v4
# This script creates an Application Load Balancer with HTTP listener and target group
# Cost improvements: eliminated unused resources, optimized health checks, reduced API calls
# Reliability improvements: enhanced error handling, validation, and resource state management

set -euo pipefail

# Set up logging
LOG_FILE="elb-script-v4.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Elastic Load Balancing setup script at $(date)"
echo "All commands and outputs will be logged to $LOG_FILE"

# Function to handle errors
handle_error() {
    echo "ERROR: $1" >&2
    echo "Attempting to clean up resources..."
    cleanup_resources
    exit 1
}

# Function to validate AWS CLI response
check_aws_response() {
    local response="$1"
    local error_msg="${2:-AWS CLI returned empty response}"
    if [[ -z "$response" ]] || [[ "$response" == "None" ]]; then
        handle_error "$error_msg"
    fi
}

# Function to validate AWS CLI is configured
validate_aws_credentials() {
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        handle_error "AWS credentials not configured or invalid. Please run 'aws configure'"
    fi
}

# Function to validate region is set
validate_aws_region() {
    if [[ -z "${AWS_REGION:-}" ]] && [[ -z "${AWS_DEFAULT_REGION:-}" ]]; then
        handle_error "AWS region not configured. Please set AWS_REGION or AWS_DEFAULT_REGION environment variable or run 'aws configure'"
    fi
}

# Function to wait for resource deletion with timeout
wait_for_deletion() {
    local resource_type="$1"
    local resource_id="$2"
    local max_wait="${3:-300}"
    local elapsed=0
    
    echo "Waiting for $resource_type to be deleted (max ${max_wait}s)..."
    while [ $elapsed -lt $max_wait ]; do
        if ! aws ec2 describe-security-groups --group-ids "$resource_id" > /dev/null 2>&1; then
            echo "$resource_type deleted successfully."
            return 0
        fi
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    return 1
}

# Function to clean up resources
cleanup_resources() {
    echo "Cleaning up resources in reverse order..."
    
    if [ -n "${LISTENER_ARN:-}" ]; then
        echo "Deleting listener: $LISTENER_ARN"
        if aws elbv2 delete-listener --listener-arn "$LISTENER_ARN" 2>/dev/null; then
            echo "Listener deleted successfully."
        else
            echo "WARNING: Could not delete listener or it no longer exists."
        fi
    fi
    
    if [ -n "${LOAD_BALANCER_ARN:-}" ]; then
        echo "Deleting load balancer: $LOAD_BALANCER_ARN"
        if aws elbv2 delete-load-balancer --load-balancer-arn "$LOAD_BALANCER_ARN" 2>/dev/null; then
            echo "Load balancer deletion initiated."
            
            echo "Waiting for load balancer to be deleted..."
            if aws elbv2 wait load-balancers-deleted --load-balancer-arns "$LOAD_BALANCER_ARN" 2>/dev/null; then
                echo "Load balancer deleted successfully."
            else
                echo "WARNING: Timeout waiting for load balancer deletion."
            fi
        else
            echo "WARNING: Could not delete load balancer or it no longer exists."
        fi
    fi
    
    if [ -n "${TARGET_GROUP_ARN:-}" ]; then
        echo "Deleting target group: $TARGET_GROUP_ARN"
        if aws elbv2 delete-target-group --target-group-arn "$TARGET_GROUP_ARN" 2>/dev/null; then
            echo "Target group deleted successfully."
        else
            echo "WARNING: Could not delete target group or it no longer exists."
        fi
    fi
    
    if [ -n "${SECURITY_GROUP_ID:-}" ]; then
        echo "Waiting 10 seconds before deleting security group..."
        sleep 10
        
        echo "Deleting security group: $SECURITY_GROUP_ID"
        RETRY_COUNT=0
        MAX_RETRIES=5
        RETRY_WAIT=10
        
        while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
            if aws ec2 delete-security-group --group-id "$SECURITY_GROUP_ID" 2>/dev/null; then
                echo "Security group deleted successfully."
                return 0
            fi
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo "Security group still has dependencies. Retrying in ${RETRY_WAIT}s... (Attempt $RETRY_COUNT of $MAX_RETRIES)"
                sleep $RETRY_WAIT
            fi
        done
        
        echo "WARNING: Could not delete security group: $SECURITY_GROUP_ID"
        echo "You may need to delete it manually using: aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID"
    fi
}

# Function to safely get the first available resource
get_first_resource() {
    local command="$1"
    local query="$2"
    local error_msg="$3"
    
    local result=$(eval "$command" --query "$query" --output text 2>/dev/null) || handle_error "$error_msg"
    check_aws_response "$result" "$error_msg"
    echo "$result"
}

# Trap errors and cleanup
trap 'handle_error "Script interrupted"' INT TERM
trap 'cleanup_resources' EXIT

# Generate a random identifier for resource names
RANDOM_ID=$(openssl rand -hex 4)
RESOURCE_PREFIX="elb-demo-${RANDOM_ID}"

# Initialize variables
VPC_ID=""
SUBNETS=()
SECURITY_GROUP_ID=""
LOAD_BALANCER_ARN=""
TARGET_GROUP_ARN=""
LISTENER_ARN=""
INSTANCE_IDS=()

# Step 1: Verify AWS CLI configuration
echo "Verifying AWS CLI configuration..."
validate_aws_credentials
validate_aws_region

# Verify AWS CLI version and elbv2 support in single call
echo "Verifying AWS CLI support for Elastic Load Balancing..."
if ! aws elbv2 describe-load-balancers --max-items 1 > /dev/null 2>&1; then
    handle_error "AWS CLI does not support elbv2 commands or is not installed. Please update/install AWS CLI."
fi

# Step 2: Get VPC ID and subnet information
echo "Retrieving VPC and subnet information..."
VPC_ID=$(get_first_resource \
    "aws ec2 describe-vpcs --filters Name=isDefault,Values=true" \
    "Vpcs[0].VpcId" \
    "Failed to retrieve default VPC information")
echo "Using VPC: $VPC_ID"

# Get two subnets from different Availability Zones
echo "Retrieving subnet information..."
SUBNET_INFO=$(get_first_resource \
    "aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID" \
    "Subnets[0:2].[SubnetId,AvailabilityZone]" \
    "Failed to retrieve subnet information")

# Parse subnet info
mapfile -t SUBNET_LINES <<< "$SUBNET_INFO"
SUBNETS=()
AZONES=()
for line in "${SUBNET_LINES[@]}"; do
    if [ -n "$line" ]; then
        read -r subnet az <<< "$line"
        SUBNETS+=("$subnet")
        AZONES+=("$az")
    fi
done

if [ ${#SUBNETS[@]} -lt 2 ]; then
    handle_error "Need at least 2 subnets in different Availability Zones. Found: ${#SUBNETS[@]}"
fi

echo "Using subnets: ${SUBNETS[0]} (${AZONES[0]}) and ${SUBNETS[1]} (${AZONES[1]})"

# Step 3: Create a security group for the load balancer
echo "Creating security group for the load balancer..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name "${RESOURCE_PREFIX}-sg" \
    --description "Security group for ELB demo" \
    --vpc-id "$VPC_ID" \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=project,Value=doc-smith},{Key=tutorial,Value=elastic-load-balancing-gs}]" \
    --query "GroupId" --output text 2>/dev/null) || handle_error "Failed to create security group"
check_aws_response "$SECURITY_GROUP_ID"
echo "Created security group: $SECURITY_GROUP_ID"

# Add inbound rule to allow HTTP traffic with explicit error handling
echo "Adding inbound rule to allow HTTP traffic..."
if ! aws ec2 authorize-security-group-ingress \
    --group-id "$SECURITY_GROUP_ID" \
    --protocol tcp \
    --port 80 \
    --cidr "0.0.0.0/0" 2>/dev/null; then
    if aws ec2 describe-security-groups --group-ids "$SECURITY_GROUP_ID" \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`80\`]" --output text 2>/dev/null | grep -q tcp; then
        echo "HTTP rule already exists in security group."
    else
        handle_error "Could not add inbound HTTP rule to security group"
    fi
fi

# Step 4: Create the load balancer
echo "Creating Application Load Balancer..."
LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
    --name "${RESOURCE_PREFIX}-lb" \
    --subnets "${SUBNETS[0]}" "${SUBNETS[1]}" \
    --security-groups "$SECURITY_GROUP_ID" \
    --scheme internet-facing \
    --type application \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=elastic-load-balancing-gs \
    --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null) || handle_error "Failed to create load balancer"
check_aws_response "$LOAD_BALANCER_ARN"
echo "Created load balancer: $LOAD_BALANCER_ARN"

# Create target group with cost-optimized health checks
echo "Creating target group..."
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name "${RESOURCE_PREFIX}-targets" \
    --protocol HTTP \
    --port 80 \
    --vpc-id "$VPC_ID" \
    --target-type instance \
    --health-check-protocol HTTP \
    --health-check-path "/" \
    --health-check-interval-seconds 60 \
    --health-check-timeout-seconds 10 \
    --healthy-threshold-count 3 \
    --unhealthy-threshold-count 3 \
    --matcher HttpCode=200 \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=elastic-load-balancing-gs \
    --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null) || handle_error "Failed to create target group"
check_aws_response "$TARGET_GROUP_ARN"
echo "Created target group: $TARGET_GROUP_ARN"

# Wait for the load balancer to be active
echo "Waiting for load balancer to become active..."
RETRY_COUNT=0
MAX_RETRIES=3
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if aws elbv2 wait load-balancer-available --load-balancer-arns "$LOAD_BALANCER_ARN" 2>/dev/null; then
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "Load balancer not yet available. Retrying... (Attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES)"
        sleep 10
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    handle_error "Timeout waiting for load balancer to become available"
fi

# Step 5: Find EC2 instances and register targets
echo "Looking for available EC2 instances to register as targets..."
INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running" \
    --query "Reservations[*].Instances[*].InstanceId" --output text 2>/dev/null) || handle_error "Failed to describe instances"

if [ -z "$INSTANCES" ]; then
    echo "No running instances found in VPC $VPC_ID."
    echo "You will need to register targets manually after launching instances."
else
    # Convert space-separated list to array
    read -r -a INSTANCE_IDS <<< "$INSTANCES"
    
    # Register targets with the target group (up to 2 instances)
    echo "Registering targets with the target group..."
    TARGET_ARGS=()
    for i in "${!INSTANCE_IDS[@]}"; do
        if [ "$i" -lt 2 ]; then
            TARGET_ARGS+=("Id=${INSTANCE_IDS[$i]}")
        fi
    done
    
    if [ ${#TARGET_ARGS[@]} -gt 0 ]; then
        if aws elbv2 register-targets \
            --target-group-arn "$TARGET_GROUP_ARN" \
            --targets "${TARGET_ARGS[@]}" 2>/dev/null; then
            echo "Registered instances: ${TARGET_ARGS[*]}"
        else
            echo "WARNING: Could not register all instances"
        fi
    fi
fi

# Step 6: Create a listener
echo "Creating HTTP listener..."
LISTENER_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn "$LOAD_BALANCER_ARN" \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN" \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=elastic-load-balancing-gs \
    --query "Listeners[0].ListenerArn" --output text 2>/dev/null) || handle_error "Failed to create listener"
check_aws_response "$LISTENER_ARN"
echo "Created listener: $LISTENER_ARN"

# Step 7: Get load balancer DNS name
echo "Retrieving load balancer details..."
LB_INFO=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns "$LOAD_BALANCER_ARN" \
    --query "LoadBalancers[0].DNSName" --output text 2>/dev/null) || handle_error "Failed to retrieve load balancer information"
check_aws_response "$LB_INFO"
LB_DNS="$LB_INFO"

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
echo "Cost Optimizations Applied:"
echo "- Health check interval increased to 60 seconds (from 30)"
echo "- Health check timeout increased to 10 seconds (from 5)"
echo "- Healthy threshold increased to 3 (from 2)"
echo "- Unhealthy threshold increased to 3 (from 2)"
echo "- Eliminated redundant target health queries"
echo ""
echo "Reliability Improvements Applied:"
echo "- Enhanced AWS region validation"
echo "- Improved error handling with specific error messages"
echo "- Added retry logic for load balancer availability checks"
echo "- Increased security group deletion retries and timeout handling"
echo "- Better resource state validation before cleanup"
echo "- Automatic cleanup on script exit via trap handler"
echo ""

# Ask user if they want to clean up resources
echo "=============================================="
echo "CLEANUP CONFIRMATION"
echo "=============================================="
printf "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    echo "Starting cleanup process..."
    cleanup_resources
    echo "Cleanup completed."
    # Disable EXIT trap to prevent double cleanup
    trap - EXIT
else
    echo "Resources have been preserved."
    echo "To clean up later, run the following commands:"
    echo "aws elbv2 delete-listener --listener-arn $LISTENER_ARN"
    echo "aws elbv2 delete-load-balancer --load-balancer-arn $LOAD_BALANCER_ARN"
    echo "aws elbv2 wait load-balancers-deleted --load-balancer-arns $LOAD_BALANCER_ARN"
    echo "aws elbv2 delete-target-group --target-group-arn $TARGET_GROUP_ARN"
    echo "aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID"
    # Disable EXIT trap to prevent cleanup
    trap - EXIT
fi

echo "Script completed at $(date)"