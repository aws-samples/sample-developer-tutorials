#!/bin/bash

# AWS Cloud Map Private Namespace Tutorial Script
# This script demonstrates how to use AWS Cloud Map for service discovery
# with DNS queries and API calls

# Exit on error
set -e
set -u
set -o pipefail

# Configuration
readonly REGION="us-east-2"
readonly NAMESPACE_NAME="cloudmap-tutorial.com"
readonly LOG_FILE="cloudmap-tutorial.log"
readonly CREATOR_REQUEST_ID=$(date +%s)
readonly MAX_RETRIES=60
readonly RETRY_INTERVAL=5
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEMP_DIR=$(mktemp -d)

# Security: Restrict log file permissions
umask 0077

# Trap to ensure temp directory cleanup
trap 'rm -rf "$TEMP_DIR"' EXIT

# Initialize global variables with defaults
FIRST_INSTANCE_ID=""
SECOND_INSTANCE_ID=""
PUBLIC_SERVICE_ID=""
BACKEND_SERVICE_ID=""
NAMESPACE_ID=""

# Function to validate AWS CLI is available and authenticated
validate_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed" >&2
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed" >&2
        exit 1
    fi
    
    if ! aws sts get-caller-identity --region "$REGION" &> /dev/null; then
        echo "Error: AWS CLI authentication failed" >&2
        exit 1
    fi
}

# Function to log messages securely
log() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # Sanitize message to prevent log injection
    message=$(printf '%s\n' "$message" | sed "s/['\"]/\\\\&/g")
    echo "$timestamp - $message" | tee -a "$LOG_FILE"
}

# Function to safely extract JSON values
safe_json_extract() {
    local json_string="$1"
    local jq_filter="$2"
    local result
    
    # Validate jq filter to prevent injection
    if ! jq -n "$jq_filter" &>/dev/null 2>&1; then
        log "Error: Invalid jq filter provided"
        return 1
    fi
    
    result=$(echo "$json_string" | jq -r "$jq_filter" 2>/dev/null)
    
    if [[ -z "$result" || "$result" == "null" ]]; then
        log "Error: Failed to extract value from JSON using filter"
        return 1
    fi
    
    echo "$result"
}

# Function to check operation status with timeout
check_operation() {
    local operation_id="$1"
    local status=""
    local retry_count=0
    
    # Validate operation_id format (basic UUID validation)
    if [[ -z "$operation_id" ]] || ! [[ "$operation_id" =~ ^[a-f0-9-]+$ ]]; then
        log "Error: Invalid operation_id format"
        return 1
    fi
    
    log "Checking operation status..."
    
    while [[ "$status" != "SUCCESS" && $retry_count -lt $MAX_RETRIES ]]; do
        sleep "$RETRY_INTERVAL"
        
        local operation_result
        if ! operation_result=$(aws servicediscovery get-operation \
            --operation-id "$operation_id" \
            --region "$REGION" \
            --output json 2>/dev/null); then
            log "Warning: Failed to get operation status, retrying..."
            ((retry_count++))
            continue
        fi
        
        if ! status=$(safe_json_extract "$operation_result" '.Operation.Status'); then
            ((retry_count++))
            continue
        fi
        
        log "Operation status: $status"
        
        if [[ "$status" == "FAIL" ]]; then
            local error_msg
            error_msg=$(safe_json_extract "$operation_result" '.Operation.ErrorProperties.ErrorMessage // "Unknown error"' || echo "Unknown error")
            log "Operation failed"
            return 1
        fi
        
        ((retry_count++))
    done
    
    if [[ "$status" != "SUCCESS" ]]; then
        log "Error: Operation did not complete within timeout period"
        return 1
    fi
    
    log "Operation completed successfully."
    return 0
}

# Function to clean up resources
cleanup() {
    log "Starting cleanup process..."
    
    local cleanup_failed=0
    
    if [[ -n "$FIRST_INSTANCE_ID" ]] && [[ -n "$PUBLIC_SERVICE_ID" ]]; then
        log "Deregistering first service instance..."
        if ! aws servicediscovery deregister-instance \
            --service-id "$PUBLIC_SERVICE_ID" \
            --instance-id "$FIRST_INSTANCE_ID" \
            --region "$REGION" &>/dev/null; then
            log "Warning: Failed to deregister first instance"
            cleanup_failed=1
        fi
    fi
    
    if [[ -n "$SECOND_INSTANCE_ID" ]] && [[ -n "$BACKEND_SERVICE_ID" ]]; then
        log "Deregistering second service instance..."
        if ! aws servicediscovery deregister-instance \
            --service-id "$BACKEND_SERVICE_ID" \
            --instance-id "$SECOND_INSTANCE_ID" \
            --region "$REGION" &>/dev/null; then
            log "Warning: Failed to deregister second instance"
            cleanup_failed=1
        fi
    fi
    
    if [[ -n "$PUBLIC_SERVICE_ID" ]]; then
        log "Deleting public service..."
        if ! aws servicediscovery delete-service \
            --id "$PUBLIC_SERVICE_ID" \
            --region "$REGION" &>/dev/null; then
            log "Warning: Failed to delete public service"
            cleanup_failed=1
        fi
    fi
    
    if [[ -n "$BACKEND_SERVICE_ID" ]]; then
        log "Deleting backend service..."
        if ! aws servicediscovery delete-service \
            --id "$BACKEND_SERVICE_ID" \
            --region "$REGION" &>/dev/null; then
            log "Warning: Failed to delete backend service"
            cleanup_failed=1
        fi
    fi
    
    if [[ -n "$NAMESPACE_ID" ]]; then
        log "Deleting namespace..."
        if ! aws servicediscovery delete-namespace \
            --id "$NAMESPACE_ID" \
            --region "$REGION" &>/dev/null; then
            log "Warning: Failed to delete namespace"
            cleanup_failed=1
        fi
    fi
    
    log "Cleanup completed."
    
    if [[ $cleanup_failed -eq 1 ]]; then
        log "Warning: Some cleanup operations failed. Please verify resource deletion manually."
    fi
}

# Set up trap for cleanup on script exit
trap cleanup EXIT INT TERM

# Validate prerequisites
validate_aws_cli

# Initialize log file with secure permissions
> "$LOG_FILE"
chmod 600 "$LOG_FILE"
log "Starting AWS Cloud Map tutorial script"

# Step 1: Create an AWS Cloud Map namespace
log "Creating AWS Cloud Map namespace"

OPERATION_RESULT=$(aws servicediscovery create-public-dns-namespace \
    --name "$NAMESPACE_NAME" \
    --creator-request-id "cloudmap-tutorial-$CREATOR_REQUEST_ID" \
    --region "$REGION" \
    --output json)

if ! OPERATION_ID=$(safe_json_extract "$OPERATION_RESULT" '.OperationId'); then
    log "Error: Failed to create namespace"
    exit 1
fi

log "Namespace creation initiated"

# Check operation status
if ! check_operation "$OPERATION_ID"; then
    log "Error: Namespace creation failed"
    exit 1
fi

# Get the namespace ID
log "Getting namespace ID..."
NAMESPACE_ID=$(aws servicediscovery list-namespaces \
    --region "$REGION" \
    --query "Namespaces[?Name=='$NAMESPACE_NAME'].Id" \
    --output text)

if [[ -z "$NAMESPACE_ID" ]] || ! [[ "$NAMESPACE_ID" =~ ^[a-f0-9-]+$ ]]; then
    log "Error: Failed to retrieve namespace ID"
    exit 1
fi

log "Namespace created successfully"

# Get the hosted zone ID
log "Getting Route 53 hosted zone ID..."
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
    --dns-name "$NAMESPACE_NAME" \
    --query "HostedZones[0].Id" \
    --output text | sed 's|/hostedzone/||')

if [[ -z "$HOSTED_ZONE_ID" ]] || ! [[ "$HOSTED_ZONE_ID" =~ ^[A-Z0-9]+$ ]]; then
    log "Error: Failed to retrieve hosted zone ID"
    exit 1
fi

log "Hosted Zone retrieved successfully"

# Step 2: Create the AWS Cloud Map services
log "Creating public service..."
PUBLIC_SERVICE_RESULT=$(aws servicediscovery create-service \
    --name "public-service" \
    --namespace-id "$NAMESPACE_ID" \
    --dns-config "RoutingPolicy=MULTIVALUE,DnsRecords=[{Type=A,TTL=300}]" \
    --region "$REGION" \
    --output json)

if ! PUBLIC_SERVICE_ID=$(safe_json_extract "$PUBLIC_SERVICE_RESULT" '.Service.Id'); then
    log "Error: Failed to create public service"
    exit 1
fi

log "Public service created successfully"

log "Creating backend service..."
BACKEND_SERVICE_RESULT=$(aws servicediscovery create-service \
    --name "backend-service" \
    --namespace-id "$NAMESPACE_ID" \
    --type "HTTP" \
    --region "$REGION" \
    --output json)

if ! BACKEND_SERVICE_ID=$(safe_json_extract "$BACKEND_SERVICE_RESULT" '.Service.Id'); then
    log "Error: Failed to create backend service"
    exit 1
fi

log "Backend service created successfully"

# Step 3: Register the AWS Cloud Map service instances
log "Registering first service instance..."
FIRST_INSTANCE_RESULT=$(aws servicediscovery register-instance \
    --service-id "$PUBLIC_SERVICE_ID" \
    --instance-id "first" \
    --attributes "AWS_INSTANCE_IPV4=192.168.2.1" \
    --region "$REGION" \
    --output json)

FIRST_INSTANCE_ID="first"

if ! FIRST_OPERATION_ID=$(safe_json_extract "$FIRST_INSTANCE_RESULT" '.OperationId'); then
    log "Error: Failed to register first instance"
    exit 1
fi

log "First instance registration initiated"

# Check operation status
if ! check_operation "$FIRST_OPERATION_ID"; then
    log "Error: First instance registration failed"
    exit 1
fi

log "Registering second service instance..."
SECOND_INSTANCE_RESULT=$(aws servicediscovery register-instance \
    --service-id "$BACKEND_SERVICE_ID" \
    --instance-id "second" \
    --attributes "service-name=backend" \
    --region "$REGION" \
    --output json)

SECOND_INSTANCE_ID="second"

if ! SECOND_OPERATION_ID=$(safe_json_extract "$SECOND_INSTANCE_RESULT" '.OperationId'); then
    log "Error: Failed to register second instance"
    exit 1
fi

log "Second instance registration initiated"

# Check operation status
if ! check_operation "$SECOND_OPERATION_ID"; then
    log "Error: Second instance registration failed"
    exit 1
fi

# Step 4: Discover the AWS Cloud Map service instances
log "Getting Route 53 name servers..."
NAME_SERVERS=$(aws route53 get-hosted-zone \
    --id "$HOSTED_ZONE_ID" \
    --query "DelegationSet.NameServers[0]" \
    --output text)

if [[ -z "$NAME_SERVERS" ]]; then
    log "Error: Failed to retrieve name servers"
    exit 1
fi

log "Name server retrieved successfully"

log "Using dig to query DNS records (this will be simulated)..."
log "Expected: DNS query would return service records"

log "Using AWS CLI to discover backend service instances..."
DISCOVER_RESULT=$(aws servicediscovery discover-instances \
    --namespace-name "$NAMESPACE_NAME" \
    --service-name "backend-service" \
    --region "$REGION" \
    --output json)

DISCOVER_OUTPUT=$(echo "$DISCOVER_RESULT" | jq -c '.' 2>/dev/null || echo "{}")
log "Discovery completed successfully"

# Display created resources
log "Resources created:"
log "- Namespace created"
log "- Public Service created"
log "- Backend Service created"
log "- Service Instances registered"

log "Proceeding with automatic resource cleanup."