#!/bin/bash

# DynamoDB Getting Started Tutorial Script
# This script demonstrates basic operations with Amazon DynamoDB:
# - Creating a table
# - Writing data to the table
# - Reading data from the table
# - Updating data in the table
# - Querying data in the table
# - Deleting the table (cleanup)

set -euo pipefail

# Set up logging with secure permissions
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dynamodb-tutorial"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/dynamodb-tutorial-$(date +%Y%m%d-%H%M%S).log"
chmod 700 "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1
chmod 600 "$LOG_FILE"

echo "Starting DynamoDB Getting Started Tutorial at $(date)"
echo "Logging to $LOG_FILE"

# Validate AWS CLI is available and configured
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed or not in PATH"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS credentials are not configured or invalid"
    exit 1
fi

# Function to check for errors in command output
check_error() {
    local output=$1
    local cmd_name=$2
    
    if echo "$output" | grep -qi "error\|failed"; then
        echo "ERROR detected in $cmd_name command:"
        echo "$output"
        return 1
    fi
    return 0
}

# Function to wait for table to be in ACTIVE state
wait_for_table_active() {
    local table_name=$1
    local max_attempts=60
    local attempt=0
    local status=""
    
    echo "Waiting for table $table_name to become ACTIVE..."
    
    while [[ "$status" != "ACTIVE" ]] && [[ $attempt -lt $max_attempts ]]; do
        sleep 5
        attempt=$((attempt + 1))
        status=$(aws dynamodb describe-table \
            --table-name "$table_name" \
            --query "Table.TableStatus" \
            --output text 2>/dev/null || echo "UNKNOWN")
        echo "Current status: $status (attempt $attempt/$max_attempts)"
    done
    
    if [[ "$status" != "ACTIVE" ]]; then
        echo "ERROR: Table $table_name did not reach ACTIVE state within timeout"
        return 1
    fi
    
    echo "Table $table_name is now ACTIVE"
    return 0
}

# Trap for cleanup on exit
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "Script exited with error code: $exit_code"
    fi
    return $exit_code
}
trap cleanup_on_exit EXIT

# Track created resources for cleanup
RESOURCES=()

# Step 1: Create a table in DynamoDB
echo "Step 1: Creating Music table in DynamoDB..."

CREATE_TABLE_OUTPUT=$(aws dynamodb create-table \
    --table-name Music \
    --attribute-definitions \
        AttributeName=Artist,AttributeType=S \
        AttributeName=SongTitle,AttributeType=S \
    --key-schema \
        AttributeName=Artist,KeyType=HASH \
        AttributeName=SongTitle,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --table-class STANDARD \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=amazon-dynamodb-gs 2>&1) || {
    echo "ERROR: Failed to create table"
    exit 1
}

check_error "$CREATE_TABLE_OUTPUT" "create-table" || exit 1
echo "$CREATE_TABLE_OUTPUT"

# Add table to resources list
RESOURCES+=("Table:Music")

# Wait for table to be active
wait_for_table_active "Music" || exit 1

# Enable point-in-time recovery (best practice)
echo "Enabling point-in-time recovery for the Music table..."

PITR_OUTPUT=$(aws dynamodb update-continuous-backups \
    --table-name Music \
    --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true 2>&1) || {
    echo "ERROR: Failed to enable PITR"
    exit 1
}

check_error "$PITR_OUTPUT" "update-continuous-backups" || exit 1
echo "$PITR_OUTPUT"

# Step 2: Write data to the DynamoDB table
echo "Step 2: Writing data to the Music table..."

# Add first item
ITEM1_OUTPUT=$(aws dynamodb put-item \
    --table-name Music \
    --item '{"Artist": {"S": "No One You Know"}, "SongTitle": {"S": "Call Me Today"}, "AlbumTitle": {"S": "Somewhat Famous"}, "Awards": {"N": "1"}}' 2>&1) || {
    echo "ERROR: Failed to put item 1"
    exit 1
}

check_error "$ITEM1_OUTPUT" "put-item (item 1)" || exit 1
echo "$ITEM1_OUTPUT"

# Add second item
ITEM2_OUTPUT=$(aws dynamodb put-item \
    --table-name Music \
    --item '{"Artist": {"S": "No One You Know"}, "SongTitle": {"S": "Howdy"}, "AlbumTitle": {"S": "Somewhat Famous"}, "Awards": {"N": "2"}}' 2>&1) || {
    echo "ERROR: Failed to put item 2"
    exit 1
}

check_error "$ITEM2_OUTPUT" "put-item (item 2)" || exit 1
echo "$ITEM2_OUTPUT"

# Add third item
ITEM3_OUTPUT=$(aws dynamodb put-item \
    --table-name Music \
    --item '{"Artist": {"S": "Acme Band"}, "SongTitle": {"S": "Happy Day"}, "AlbumTitle": {"S": "Songs About Life"}, "Awards": {"N": "10"}}' 2>&1) || {
    echo "ERROR: Failed to put item 3"
    exit 1
}

check_error "$ITEM3_OUTPUT" "put-item (item 3)" || exit 1
echo "$ITEM3_OUTPUT"

# Add fourth item
ITEM4_OUTPUT=$(aws dynamodb put-item \
    --table-name Music \
    --item '{"Artist": {"S": "Acme Band"}, "SongTitle": {"S": "PartiQL Rocks"}, "AlbumTitle": {"S": "Another Album Title"}, "Awards": {"N": "8"}}' 2>&1) || {
    echo "ERROR: Failed to put item 4"
    exit 1
}

check_error "$ITEM4_OUTPUT" "put-item (item 4)" || exit 1
echo "$ITEM4_OUTPUT"

# Step 3: Read data from the DynamoDB table
echo "Step 3: Reading data from the Music table..."

# Get a specific item
GET_ITEM_OUTPUT=$(aws dynamodb get-item \
    --consistent-read \
    --table-name Music \
    --key '{"Artist": {"S": "Acme Band"}, "SongTitle": {"S": "Happy Day"}}' 2>&1) || {
    echo "ERROR: Failed to get item"
    exit 1
}

check_error "$GET_ITEM_OUTPUT" "get-item" || exit 1
echo "Retrieved item:"
echo "$GET_ITEM_OUTPUT"

# Step 4: Update data in the DynamoDB table
echo "Step 4: Updating data in the Music table..."

# Update an item
UPDATE_ITEM_OUTPUT=$(aws dynamodb update-item \
    --table-name Music \
    --key '{"Artist": {"S": "Acme Band"}, "SongTitle": {"S": "Happy Day"}}' \
    --update-expression "SET AlbumTitle = :newval" \
    --expression-attribute-values '{":newval": {"S": "Updated Album Title"}}' \
    --return-values ALL_NEW 2>&1) || {
    echo "ERROR: Failed to update item"
    exit 1
}

check_error "$UPDATE_ITEM_OUTPUT" "update-item" || exit 1
echo "Updated item:"
echo "$UPDATE_ITEM_OUTPUT"

# Step 5: Query data in the DynamoDB table
echo "Step 5: Querying data in the Music table..."

# Query items by Artist
QUERY_OUTPUT=$(aws dynamodb query \
    --table-name Music \
    --key-condition-expression "Artist = :name" \
    --expression-attribute-values '{":name": {"S": "Acme Band"}}' 2>&1) || {
    echo "ERROR: Failed to query items"
    exit 1
}

check_error "$QUERY_OUTPUT" "query" || exit 1
echo "Query results:"
echo "$QUERY_OUTPUT"

# Prompt for cleanup
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Resources created:"
for resource in "${RESOURCES[@]}"; do
    echo "- $resource"
done
echo ""

# Set timeout for read command and validate input
read -r -t 30 -p "Do you want to clean up all created resources? (y/n): " CLEANUP_CHOICE || CLEANUP_CHOICE="n"

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    # Step 6: Delete the DynamoDB table
    echo "Step 6: Deleting the Music table..."
    
    DELETE_TABLE_OUTPUT=$(aws dynamodb delete-table --table-name Music 2>&1) || {
        echo "ERROR: Failed to delete table"
        exit 1
    }
    
    check_error "$DELETE_TABLE_OUTPUT" "delete-table" || exit 1
    echo "$DELETE_TABLE_OUTPUT"
    
    echo "Waiting for table deletion to complete..."
    aws dynamodb wait table-not-exists --table-name Music || {
        echo "ERROR: Failed waiting for table deletion"
        exit 1
    }
    
    echo "Cleanup completed successfully."
else
    echo "Skipping cleanup. Resources will remain in your AWS account."
fi

echo "DynamoDB Getting Started Tutorial completed at $(date)"
echo "Log file: $LOG_FILE"