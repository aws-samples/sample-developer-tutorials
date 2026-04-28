#!/bin/bash

# Amazon ElastiCache Getting Started Script
# This script creates a Valkey serverless cache, configures security groups,
# and demonstrates how to connect to and use the cache.

set -euo pipefail

# Set up logging
LOG_FILE="elasticache_tutorial_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting ElastiCache tutorial script. Logging to $LOG_FILE"
echo "============================================================"

# Cleanup on exit
cleanup_on_exit() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Script failed with exit code $exit_code"
    fi
    return $exit_code
}
trap cleanup_on_exit EXIT

# Function to handle errors
handle_error() {
    echo "ERROR: $1" >&2
    echo "Resources created:"
    if [ -n "${CACHE_NAME:-}" ]; then
        echo "- ElastiCache serverless cache: $CACHE_NAME"
    fi
    if [ -n "${SG_RULE_6379:-}" ] || [ -n "${SG_RULE_6380:-}" ]; then
        echo "- Security group rules for ports 6379 and 6380"
    fi
    echo "Please clean up these resources manually."
    exit 1
}

# Input validation function
validate_input() {
    local input="$1"
    if [[ ! "$input" =~ ^[a-zA-Z0-9-]*$ ]]; then
        handle_error "Invalid characters in input"
    fi
}

# AWS CLI error checking function with jq parsing
check_aws_error() {
    local output="$1"
    local error_msg="$2"
    
    if echo "$output" | grep -qi "error\|failed\|invalid"; then
        if ! echo "$output" | grep -qi "already exists"; then
            handle_error "$error_msg: $output"
        fi
    fi
}

# Validate AWS credentials are configured
if ! aws sts get-caller-identity &>/dev/null; then
    handle_error "AWS credentials are not configured. Please configure AWS CLI before running this script."
fi

# Generate a random identifier for resource names
RANDOM_ID=$(head -c 8 /dev/urandom | LC_ALL=C tr -dc 'a-z0-9')
CACHE_NAME="valkey-cache-${RANDOM_ID}"

validate_input "$CACHE_NAME"
echo "Using cache name: $CACHE_NAME"

# Step 1: Set up security group for ElastiCache access
echo "Step 1: Setting up security group for ElastiCache access..."

# Get default security group ID with jq for more reliable parsing
echo "Getting default security group ID..."
SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=default \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null) || handle_error "Failed to query security groups"

if [[ -z "$SG_ID" || "$SG_ID" == "None" ]]; then
    handle_error "Failed to get default security group ID"
fi

echo "Default security group ID: $SG_ID"

# Validate SG_ID format
if ! [[ "$SG_ID" =~ ^sg- ]]; then
    handle_error "Invalid security group ID format"
fi

# Function to add security group rule
add_sg_rule() {
    local port=$1
    local rule_var=$2
    
    echo "Adding inbound rule for port $port..."
    local result
    result=$(aws ec2 authorize-security-group-ingress \
      --group-id "$SG_ID" \
      --protocol tcp \
      --port "$port" \
      --cidr 0.0.0.0/0 \
      --tag-specifications 'ResourceType=security-group-rule,Tags=[{Key=project,Value=doc-smith},{Key=tutorial,Value=amazon-elasticache-gs}]' \
      --query "SecurityGroupRules[0].SecurityGroupRuleId" \
      --output text 2>&1 || true)
    
    if echo "$result" | grep -qi "error"; then
        if echo "$result" | grep -qi "already exists"; then
            echo "Rule for port $port already exists, continuing..."
            eval "$rule_var=existing"
        else
            handle_error "Failed to add security group rule for port $port: $result"
        fi
    else
        eval "$rule_var=$result"
    fi
}

# Add inbound rules for both ports
add_sg_rule 6379 SG_RULE_6379
add_sg_rule 6380 SG_RULE_6380

echo "Security group rules added successfully."
echo ""
echo "SECURITY WARNING: The security group rules created allow access from any IP address (0.0.0.0/0)."
echo "This is NOT RECOMMENDED for production environments."
echo "For production deployments, restrict access to specific IP ranges or security groups."
echo ""

# Step 2: Create a Valkey serverless cache
echo "Step 2: Creating Valkey serverless cache..."
CREATE_RESULT=$(aws elasticache create-serverless-cache \
  --serverless-cache-name "$CACHE_NAME" \
  --engine valkey \
  --tags Key=project,Value=doc-smith Key=tutorial,Value=amazon-elasticache-gs 2>&1) || handle_error "Failed to create serverless cache"

check_aws_error "$CREATE_RESULT" "Cache creation failed"

echo "Cache creation initiated. Waiting for cache to become available..."

# Step 3: Check the status of the cache creation with optimized polling
echo "Step 3: Checking cache status..."

MAX_ATTEMPTS=30
ATTEMPT=1
CACHE_STATUS=""
POLL_INTERVAL=10

while [[ $ATTEMPT -le $MAX_ATTEMPTS ]]; do
    echo "Checking cache status (attempt $ATTEMPT of $MAX_ATTEMPTS)..."
    
    DESCRIBE_RESULT=$(aws elasticache describe-serverless-caches \
      --serverless-cache-name "$CACHE_NAME" \
      --query "ServerlessCaches[0].Status" \
      --output text 2>&1) || handle_error "Failed to describe serverless cache"
    
    check_aws_error "$DESCRIBE_RESULT" "Cache description failed"
    
    CACHE_STATUS="${DESCRIBE_RESULT}"
    
    echo "Current status: ${CACHE_STATUS:-unknown}"
    
    if [[ "${CACHE_STATUS,,}" == "available" ]]; then
        echo "Cache is now available!"
        break
    elif [[ "${CACHE_STATUS,,}" == "create-failed" ]]; then
        handle_error "Cache creation failed. Please check the AWS console for details."
    fi
    
    if [[ $ATTEMPT -lt $MAX_ATTEMPTS ]]; then
        echo "Waiting $POLL_INTERVAL seconds before next check..."
        sleep "$POLL_INTERVAL"
    fi
    
    ((ATTEMPT++))
done

if [[ "${CACHE_STATUS,,}" != "available" ]]; then
    handle_error "Cache did not become available within the expected time. Last status: ${CACHE_STATUS:-unknown}"
fi

# Step 4: Find your cache endpoint with jq parsing
echo "Step 4: Getting cache endpoint..."
ENDPOINT=$(aws elasticache describe-serverless-caches \
  --serverless-cache-name "$CACHE_NAME" \
  --query "ServerlessCaches[0].Endpoint.Address" \
  --output text 2>&1) || handle_error "Failed to retrieve endpoint"

if [[ -z "$ENDPOINT" || "$ENDPOINT" == "None" ]]; then
    handle_error "Failed to get cache endpoint"
fi

echo "Cache endpoint: $ENDPOINT"

# Validate endpoint format (basic check)
if ! [[ "$ENDPOINT" =~ \. ]]; then
    handle_error "Invalid endpoint format"
fi

# Step 5: Instructions for connecting to the cache
echo ""
echo "============================================================"
echo "Your Valkey serverless cache has been successfully created!"
echo "Cache Name: $CACHE_NAME"
echo "Endpoint: $ENDPOINT"
echo "============================================================"
echo ""
echo "To connect to your cache from an EC2 instance, follow these steps:"
echo ""
echo "1. Install valkey-cli on your EC2 instance:"
echo "   sudo amazon-linux-extras install epel -y"
echo "   sudo yum install gcc jemalloc-devel openssl-devel tcl tcl-devel -y"
echo "   wget https://github.com/valkey-io/valkey/archive/refs/tags/8.0.0.tar.gz"
echo "   tar xvzf 8.0.0.tar.gz"
echo "   cd valkey-8.0.0"
echo "   make BUILD_TLS=yes"
echo ""
echo "2. Connect to your cache using valkey-cli:"
echo "   src/valkey-cli -h $ENDPOINT --tls -p 6379"
echo ""
echo "3. Once connected, you can run commands like:"
echo "   set mykey \"Hello ElastiCache\""
echo "   get mykey"
echo ""

# Prompt for cleanup with timeout
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Resources created:"
echo "- ElastiCache serverless cache: $CACHE_NAME"
if [ "${SG_RULE_6379:-}" != "existing" ] || [ "${SG_RULE_6380:-}" != "existing" ]; then
    echo "- Security group rules for ports 6379 and 6380"
fi
echo ""
echo "Do you want to clean up all created resources? (y/n): "

read -r -t 300 CLEANUP_CHOICE || CLEANUP_CHOICE="n"

if [[ "${CLEANUP_CHOICE,,}" == "y" ]]; then
    echo "Starting cleanup process..."
    
    # Step 6: Delete the cache
    echo "Deleting serverless cache $CACHE_NAME..."
    DELETE_RESULT=$(aws elasticache delete-serverless-cache \
      --serverless-cache-name "$CACHE_NAME" 2>&1 || true)
    
    if echo "$DELETE_RESULT" | grep -qi "error"; then
        if ! echo "$DELETE_RESULT" | grep -qi "cache cluster not found"; then
            echo "WARNING: Failed to delete serverless cache: $DELETE_RESULT"
            echo "Please delete the cache manually from the AWS console."
        fi
    else
        echo "Cache deletion initiated. This may take several minutes to complete."
    fi
    
    # Function to revoke security group rule
    revoke_sg_rule() {
        local port=$1
        local rule_var=$2
        
        if [ "${!rule_var:-}" != "existing" ]; then
            echo "Removing security group rule for port $port..."
            aws ec2 revoke-security-group-ingress \
              --group-id "$SG_ID" \
              --protocol tcp \
              --port "$port" \
              --cidr 0.0.0.0/0 2>/dev/null || true
        fi
    }
    
    # Revoke security group rules
    revoke_sg_rule 6379 SG_RULE_6379
    revoke_sg_rule 6380 SG_RULE_6380
    
    echo "Cleanup completed."
else
    echo "Cleanup skipped. Resources will remain in your AWS account."
    echo "To clean up later, run:"
    echo "aws elasticache delete-serverless-cache --serverless-cache-name $CACHE_NAME"
    if [ "${SG_RULE_6379:-}" != "existing" ] || [ "${SG_RULE_6380:-}" != "existing" ]; then
        echo "And remove the security group rules for ports 6379 and 6380 from security group $SG_ID"
    fi
fi

echo ""
echo "Script completed. See $LOG_FILE for the full log."
echo "============================================================"