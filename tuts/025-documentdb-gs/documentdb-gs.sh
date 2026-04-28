#!/bin/bash
# Amazon DocumentDB - Getting Started
# This script creates a DocumentDB cluster with encrypted storage, stores the
# master password in Secrets Manager, and displays connection information.

set -eE

###############################################################################
# Configuration
###############################################################################
SUFFIX=$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' ' | cut -c1-8)
CLUSTER_ID="docdb-gs-${SUFFIX}"
INSTANCE_ID="${CLUSTER_ID}-inst"
SUBNET_GROUP_NAME="docdb-subnet-${SUFFIX}"
SECRET_NAME="docdb-secret-${SUFFIX}"
MASTER_USER="docdbadmin"
ENGINE_VERSION="5.0.0"
INSTANCE_CLASS="db.t3.medium"
DOCDB_PORT=27017
WAIT_TIMEOUT=900

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
LOG_FILE="${TEMP_DIR}/documentdb-gs.log"

CREATED_RESOURCES=()

TAGS="Key=project,Value=doc-smith Key=tutorial,Value=documentdb-gs"

# AWS CLI configuration
AWS_CLI_OPTS="--no-cli-pager"

###############################################################################
# Logging
###############################################################################
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Log file: $LOG_FILE"
echo ""

###############################################################################
# Region pre-check
###############################################################################
CONFIGURED_REGION=$(aws configure get region 2>/dev/null || true)
if [ -z "$CONFIGURED_REGION" ] && [ -z "$AWS_DEFAULT_REGION" ] && [ -z "$AWS_REGION" ]; then
    echo "ERROR: No AWS region configured."
    echo "Run 'aws configure set region <region>' or export AWS_DEFAULT_REGION."
    exit 1
fi
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-$CONFIGURED_REGION}}"
echo "Using region: $REGION"
echo ""

###############################################################################
# Input validation function
###############################################################################
validate_input() {
    local input="$1"
    local max_length="${2:-255}"
    
    if [ ${#input} -gt "$max_length" ]; then
        echo "ERROR: Input exceeds maximum length of $max_length characters."
        return 1
    fi
    
    if [[ "$input" =~ [^\w\-] ]]; then
        echo "ERROR: Input contains invalid characters."
        return 1
    fi
    
    return 0
}

###############################################################################
# Error handler
###############################################################################
handle_error() {
    echo ""
    echo "==========================================="
    echo "ERROR at $1"
    echo "==========================================="
    echo ""
    if [ ${#CREATED_RESOURCES[@]} -gt 0 ]; then
        echo "Resources created before error:"
        for r in "${CREATED_RESOURCES[@]}"; do
            echo "  - $r"
        done
        echo ""
        echo "Attempting cleanup..."
        cleanup_resources
    fi
    exit 1
}

trap 'handle_error "line $LINENO"' ERR

###############################################################################
# Wait function
###############################################################################
wait_for_status() {
    local resource_type="$1"
    local resource_id="$2"
    local target_status="$3"
    local timeout="${4:-$WAIT_TIMEOUT}"
    local elapsed=0
    local interval=30

    validate_input "$resource_id" 100 || return 1

    echo "Waiting for $resource_type '$resource_id' to reach '$target_status'..."

    while true; do
        local current_status=""
        if [ "$resource_type" = "cluster" ]; then
            current_status=$(aws docdb describe-db-clusters $AWS_CLI_OPTS \
                --db-cluster-identifier "$resource_id" \
                --query "DBClusters[0].Status" --output text 2>&1)
        elif [ "$resource_type" = "instance" ]; then
            current_status=$(aws docdb describe-db-instances $AWS_CLI_OPTS \
                --db-instance-identifier "$resource_id" \
                --query "DBInstances[0].DBInstanceStatus" --output text 2>&1)
        fi

        if echo "$current_status" | grep -iq "error\|none"; then
            echo "ERROR checking status: $current_status"
            return 1
        fi

        echo "  Status: $current_status ($elapsed/${timeout}s)"

        if [ "$current_status" = "$target_status" ]; then
            echo "  $resource_type '$resource_id' is now '$target_status'."
            return 0
        fi

        if [ "$elapsed" -ge "$timeout" ]; then
            echo "ERROR: Timed out after ${timeout}s waiting for $resource_type '$resource_id'."
            return 1
        fi

        sleep "$interval"
        elapsed=$((elapsed + interval))
    done
}

###############################################################################
# Wait for deletion
###############################################################################
wait_for_deletion() {
    local resource_type="$1"
    local resource_id="$2"
    local timeout="${3:-$WAIT_TIMEOUT}"
    local elapsed=0
    local interval=30

    validate_input "$resource_id" 100 || return 1

    echo "Waiting for $resource_type '$resource_id' to be deleted..."

    while true; do
        local result=""
        if [ "$resource_type" = "cluster" ]; then
            result=$(aws docdb describe-db-clusters $AWS_CLI_OPTS \
                --db-cluster-identifier "$resource_id" \
                --query "DBClusters[0].Status" --output text 2>&1) || true
        elif [ "$resource_type" = "instance" ]; then
            result=$(aws docdb describe-db-instances $AWS_CLI_OPTS \
                --db-instance-identifier "$resource_id" \
                --query "DBInstances[0].DBInstanceStatus" --output text 2>&1) || true
        fi

        if echo "$result" | grep -iq "DBClusterNotFoundFault\|DBInstanceNotFound\|not found"; then
            echo "  $resource_type '$resource_id' deleted."
            return 0
        fi

        echo "  Still deleting... ($elapsed/${timeout}s)"

        if [ "$elapsed" -ge "$timeout" ]; then
            echo "WARNING: Timed out waiting for $resource_type '$resource_id' deletion."
            return 1
        fi

        sleep "$interval"
        elapsed=$((elapsed + interval))
    done
}

###############################################################################
# Cleanup
###############################################################################
cleanup_resources() {
    echo ""
    echo "Cleaning up resources..."
    echo ""

    # Revoke security group ingress rule
    if [ -n "${SG_ID:-}" ] && [ -n "${MY_IP:-}" ]; then
        echo "Revoking security group ingress rule..."
        if validate_input "$SG_ID" 100 && validate_input "$MY_IP" 50; then
            aws ec2 revoke-security-group-ingress $AWS_CLI_OPTS \
                --group-id "$SG_ID" \
                --protocol tcp \
                --port "$DOCDB_PORT" \
                --cidr "${MY_IP}/32" 2>&1 || echo "WARNING: Failed to revoke SG ingress rule."
        fi
    fi

    # Delete instance (must be deleted before cluster)
    if printf '%s\n' "${CREATED_RESOURCES[@]}" | grep -q "instance:"; then
        echo "Deleting instance '${INSTANCE_ID}'..."
        if validate_input "$INSTANCE_ID" 100; then
            aws docdb delete-db-instance $AWS_CLI_OPTS \
                --db-instance-identifier "$INSTANCE_ID" 2>&1 || echo "WARNING: Failed to delete instance."
            wait_for_deletion "instance" "$INSTANCE_ID" || true
        fi
    fi

    # Delete cluster (skip final snapshot)
    if printf '%s\n' "${CREATED_RESOURCES[@]}" | grep -q "cluster:"; then
        echo "Deleting cluster '${CLUSTER_ID}'..."
        if validate_input "$CLUSTER_ID" 100; then
            aws docdb delete-db-cluster $AWS_CLI_OPTS \
                --db-cluster-identifier "$CLUSTER_ID" \
                --skip-final-snapshot 2>&1 || echo "WARNING: Failed to delete cluster."
            wait_for_deletion "cluster" "$CLUSTER_ID" || true
        fi
    fi

    # Delete subnet group (must wait for cluster deletion)
    if printf '%s\n' "${CREATED_RESOURCES[@]}" | grep -q "subnet-group:"; then
        echo "Deleting subnet group '${SUBNET_GROUP_NAME}'..."
        if validate_input "$SUBNET_GROUP_NAME" 100; then
            aws docdb delete-db-subnet-group $AWS_CLI_OPTS \
                --db-subnet-group-name "$SUBNET_GROUP_NAME" 2>&1 || echo "WARNING: Failed to delete subnet group."
        fi
    fi

    # Delete secret
    if printf '%s\n' "${CREATED_RESOURCES[@]}" | grep -q "secret:"; then
        echo "Deleting secret '${SECRET_NAME}'..."
        if validate_input "$SECRET_NAME" 100; then
            aws secretsmanager delete-secret $AWS_CLI_OPTS \
                --secret-id "$SECRET_NAME" \
                --force-delete-without-recovery 2>&1 || echo "WARNING: Failed to delete secret."
        fi
    fi

    echo ""
    echo "Cleanup complete."
}

###############################################################################
# Step 1: Generate password and store in Secrets Manager
###############################################################################
echo "==========================================="
echo "Step 1: Create master password in Secrets Manager"
echo "==========================================="
echo ""

# Generate a cryptographically secure password
MASTER_PASSWORD=$(openssl rand -base64 24 | tr -d '=+/' | cut -c1-20)

if [ -z "$MASTER_PASSWORD" ]; then
    echo "ERROR: Failed to generate password."
    exit 1
fi

SECRET_OUTPUT=$(aws secretsmanager create-secret $AWS_CLI_OPTS \
    --name "$SECRET_NAME" \
    --description "DocumentDB master password for ${CLUSTER_ID}" \
    --secret-string "$MASTER_PASSWORD" \
    --tags "$TAGS" \
    --output text --query "ARN" 2>&1)

if echo "$SECRET_OUTPUT" | grep -iq "error"; then
    echo "ERROR creating secret: $SECRET_OUTPUT"
    exit 1
fi

SECRET_ARN="$SECRET_OUTPUT"
CREATED_RESOURCES+=("secret:${SECRET_NAME}")
echo "Secret created: $SECRET_NAME"
echo "Secret ARN: $SECRET_ARN"
echo ""

###############################################################################
# Step 2: Find default VPC and subnets
###############################################################################
echo "==========================================="
echo "Step 2: Find default VPC and subnets"
echo "==========================================="
echo ""

VPC_ID=$(aws ec2 describe-vpcs $AWS_CLI_OPTS \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" --output text 2>&1)

if echo "$VPC_ID" | grep -iq "error"; then
    echo "ERROR finding default VPC: $VPC_ID"
    exit 1
fi

if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
    echo "ERROR: No default VPC found. Create one with 'aws ec2 create-default-vpc'."
    exit 1
fi

if ! validate_input "$VPC_ID" 100; then
    echo "ERROR: Invalid VPC ID format."
    exit 1
fi

echo "Default VPC: $VPC_ID"

# Get subnets in at least 2 different AZs (space-separated)
SUBNET_INFO=$(aws ec2 describe-subnets $AWS_CLI_OPTS \
    --filters "Name=vpc-id,Values=${VPC_ID}" "Name=default-for-az,Values=true" \
    --query "Subnets[*].[SubnetId,AvailabilityZone]" --output text 2>&1)

if echo "$SUBNET_INFO" | grep -iq "error"; then
    echo "ERROR finding subnets: $SUBNET_INFO"
    exit 1
fi

# Collect unique AZs and their subnet IDs
declare -A AZ_SUBNETS
while IFS=$'\t' read -r sid az; do
    if validate_input "$sid" 100 && validate_input "$az" 50; then
        if [ -z "${AZ_SUBNETS[$az]+x}" ]; then
            AZ_SUBNETS[$az]="$sid"
        fi
    fi
done <<< "$SUBNET_INFO"

AZ_COUNT=${#AZ_SUBNETS[@]}
if [ "$AZ_COUNT" -lt 2 ]; then
    echo "ERROR: DocumentDB requires subnets in at least 2 AZs. Found $AZ_COUNT."
    exit 1
fi

# Build space-separated subnet ID list
SUBNET_IDS=""
for az in "${!AZ_SUBNETS[@]}"; do
    if [ -n "$SUBNET_IDS" ]; then
        SUBNET_IDS="${SUBNET_IDS} ${AZ_SUBNETS[$az]}"
    else
        SUBNET_IDS="${AZ_SUBNETS[$az]}"
    fi
done

echo "Subnets (${AZ_COUNT} AZs): $SUBNET_IDS"
echo ""

###############################################################################
# Step 3: Create subnet group
###############################################################################
echo "==========================================="
echo "Step 3: Create DocumentDB subnet group"
echo "==========================================="
echo ""

if ! validate_input "$SUBNET_GROUP_NAME" 100; then
    echo "ERROR: Invalid subnet group name format."
    exit 1
fi

SUBNET_GROUP_OUTPUT=$(aws docdb create-db-subnet-group $AWS_CLI_OPTS \
    --db-subnet-group-name "$SUBNET_GROUP_NAME" \
    --db-subnet-group-description "Subnet group for DocumentDB getting started" \
    --subnet-ids $SUBNET_IDS \
    --tags "$TAGS" \
    --query "DBSubnetGroup.DBSubnetGroupName" --output text 2>&1)

if echo "$SUBNET_GROUP_OUTPUT" | grep -iq "error"; then
    echo "ERROR creating subnet group: $SUBNET_GROUP_OUTPUT"
    exit 1
fi

CREATED_RESOURCES+=("subnet-group:${SUBNET_GROUP_NAME}")
echo "Subnet group created: $SUBNET_GROUP_NAME"
echo ""

###############################################################################
# Step 4: Create DocumentDB cluster
###############################################################################
echo "==========================================="
echo "Step 4: Create DocumentDB cluster"
echo "==========================================="
echo ""

if ! validate_input "$CLUSTER_ID" 100 || ! validate_input "$MASTER_USER" 50; then
    echo "ERROR: Invalid cluster or user name format."
    exit 1
fi

CLUSTER_OUTPUT=$(aws docdb create-db-cluster $AWS_CLI_OPTS \
    --db-cluster-identifier "$CLUSTER_ID" \
    --engine docdb \
    --engine-version "$ENGINE_VERSION" \
    --master-username "$MASTER_USER" \
    --master-user-password "$MASTER_PASSWORD" \
    --db-subnet-group-name "$SUBNET_GROUP_NAME" \
    --storage-encrypted \
    --no-deletion-protection \
    --tags "$TAGS" \
    --query "DBCluster.DBClusterIdentifier" --output text 2>&1)

if echo "$CLUSTER_OUTPUT" | grep -iq "error"; then
    echo "ERROR creating cluster: $CLUSTER_OUTPUT"
    exit 1
fi

CREATED_RESOURCES+=("cluster:${CLUSTER_ID}")
echo "Cluster created: $CLUSTER_ID"
echo ""

wait_for_status "cluster" "$CLUSTER_ID" "available"
echo ""

###############################################################################
# Step 5: Create DocumentDB instance
###############################################################################
echo "==========================================="
echo "Step 5: Create DocumentDB instance"
echo "==========================================="
echo ""

if ! validate_input "$INSTANCE_ID" 100; then
    echo "ERROR: Invalid instance ID format."
    exit 1
fi

INSTANCE_OUTPUT=$(aws docdb create-db-instance $AWS_CLI_OPTS \
    --db-instance-identifier "$INSTANCE_ID" \
    --db-instance-class "$INSTANCE_CLASS" \
    --db-cluster-identifier "$CLUSTER_ID" \
    --engine docdb \
    --tags "$TAGS" \
    --query "DBInstance.DBInstanceIdentifier" --output text 2>&1)

if echo "$INSTANCE_OUTPUT" | grep -iq "error"; then
    echo "ERROR creating instance: $INSTANCE_OUTPUT"
    exit 1
fi

CREATED_RESOURCES+=("instance:${INSTANCE_ID}")
echo "Instance created: $INSTANCE_ID"
echo ""

wait_for_status "instance" "$INSTANCE_ID" "available"
echo ""

###############################################################################
# Step 6: Get cluster endpoint and security group
###############################################################################
echo "==========================================="
echo "Step 6: Get cluster endpoint and security group"
echo "==========================================="
echo ""

CLUSTER_DETAILS=$(aws docdb describe-db-clusters $AWS_CLI_OPTS \
    --db-cluster-identifier "$CLUSTER_ID" \
    --query "DBClusters[0].[Endpoint,VpcSecurityGroups[0].VpcSecurityGroupId]" \
    --output text 2>&1)

if echo "$CLUSTER_DETAILS" | grep -iq "error"; then
    echo "ERROR getting cluster details: $CLUSTER_DETAILS"
    exit 1
fi

CLUSTER_ENDPOINT=$(echo "$CLUSTER_DETAILS" | awk '{print $1}')
SG_ID=$(echo "$CLUSTER_DETAILS" | awk '{print $2}')

if ! validate_input "$SG_ID" 50 || [ -z "$CLUSTER_ENDPOINT" ]; then
    echo "ERROR: Invalid cluster endpoint or security group ID."
    exit 1
fi

echo "Cluster endpoint: $CLUSTER_ENDPOINT"
echo "Security group: $SG_ID"
echo ""

# Tag the security group
aws ec2 create-tags $AWS_CLI_OPTS \
    --resources "$SG_ID" \
    --tags "$TAGS" 2>&1 || echo "WARNING: Failed to tag security group."

###############################################################################
# Step 7: Add security group ingress for port 27017 from user's IP
###############################################################################
echo "==========================================="
echo "Step 7: Add security group ingress rule"
echo "==========================================="
echo ""

# Get the user's public IP with timeout
MY_IP=$(timeout 5 curl -s https://checkip.amazonaws.com 2>&1 || echo "")

if [ -z "$MY_IP" ] || echo "$MY_IP" | grep -iq "error\|could not\|failed"; then
    echo "WARNING: Could not determine public IP address. Skipping security group rule."
    MY_IP=""
else
    # Trim whitespace and validate IP format
    MY_IP=$(echo "$MY_IP" | tr -d '[:space:]')
    
    if ! [[ "$MY_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "WARNING: Invalid IP format detected. Skipping security group rule."
        MY_IP=""
    else
        echo "Your public IP: $MY_IP"

        SG_RULE_OUTPUT=$(aws ec2 authorize-security-group-ingress $AWS_CLI_OPTS \
            --group-id "$SG_ID" \
            --protocol tcp \
            --port "$DOCDB_PORT" \
            --cidr "${MY_IP}/32" 2>&1)

        if echo "$SG_RULE_OUTPUT" | grep -iq "error"; then
            # Ignore if rule already exists
            if echo "$SG_RULE_OUTPUT" | grep -iq "Duplicate"; then
                echo "Ingress rule already exists."
            else
                echo "ERROR adding ingress rule: $SG_RULE_OUTPUT"
                exit 1
            fi
        else
            echo "Ingress rule added: TCP ${DOCDB_PORT} from ${MY_IP}/32"
            CREATED_RESOURCES+=("sg-rule:${SG_ID}:${MY_IP}")
        fi
    fi
fi

echo ""

###############################################################################
# Step 8: Download CA certificate
###############################################################################
echo "==========================================="
echo "Step 8: Download Amazon DocumentDB CA certificate"
echo "==========================================="
echo ""

CA_CERT_PATH="${TEMP_DIR}/global-bundle.pem"
timeout 10 curl -s -o "$CA_CERT_PATH" https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem 2>&1

if [ ! -s "$CA_CERT_PATH" ]; then
    echo "WARNING: Failed to download CA certificate."
else
    # Verify PEM file format
    if grep -q "BEGIN CERTIFICATE" "$CA_CERT_PATH"; then
        echo "CA certificate downloaded to: $CA_CERT_PATH"
    else
        echo "WARNING: Downloaded file does not appear to be a valid certificate."
    fi
fi
echo ""

###############################################################################
# Step 9: Display connection information
###############################################################################
echo "==========================================="
echo "CONNECTION INFORMATION"
echo "==========================================="
echo ""
echo "Cluster endpoint : $CLUSTER_ENDPOINT"
echo "Port             : $DOCDB_PORT"
echo "Master username  : $MASTER_USER"
echo "Secret name      : $SECRET_NAME (contains password)"
echo "Security group   : $SG_ID"
echo "CA certificate   : $CA_CERT_PATH"
echo ""
echo "To connect with mongosh:"
echo "  mongosh --tls --host ${CLUSTER_ENDPOINT} --tlsCAFile ${CA_CERT_PATH} \\"
echo "    --retryWrites false --username ${MASTER_USER} --password \$(aws secretsmanager get-secret-value --secret-id ${SECRET_NAME} --query SecretString --output text)"
echo ""

###############################################################################
# Step 10: Cleanup
###############################################################################
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo ""
echo "Resources created:"
for r in "${CREATED_RESOURCES[@]}"; do
    echo "  - $r"
done
echo ""
echo "Do you want to clean up all created resources? (y/n): "
read -r -t 30 CLEANUP_CHOICE || CLEANUP_CHOICE="n"

if [ "$CLEANUP_CHOICE" = "y" ] || [ "$CLEANUP_CHOICE" = "Y" ]; then
    cleanup_resources
else
    echo ""
    echo "Resources were NOT deleted. To clean up manually, run:"
    echo ""
    if [ -n "$MY_IP" ]; then
        echo "  # Revoke security group ingress rule"
        echo "  aws ec2 revoke-security-group-ingress --group-id ${SG_ID} --protocol tcp --port ${DOCDB_PORT} --cidr ${MY_IP}/32"
        echo ""
    fi
    echo "  # Delete instance (wait for it to finish before deleting cluster)"
    echo "  aws docdb delete-db-instance --db-instance-identifier ${INSTANCE_ID}"
    echo "  aws docdb wait db-instance-deleted --db-instance-identifier ${INSTANCE_ID}"
    echo ""
    echo "  # Delete cluster"
    echo "  aws docdb delete-db-cluster --db-cluster-identifier ${CLUSTER_ID} --skip-final-snapshot"
    echo ""
    echo "  # Delete subnet group (after cluster is deleted)"
    echo "  aws docdb delete-db-subnet-group --db-subnet-group-name ${SUBNET_GROUP_NAME}"
    echo ""
    echo "  # Delete secret"
    echo "  aws secretsmanager delete-secret --secret-id ${SECRET_NAME} --force-delete-without-recovery"
    echo ""
fi

echo "Done."