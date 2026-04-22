#!/bin/bash

# DynamoDB Getting Started Tutorial Script
# This script demonstrates basic operations with Amazon DynamoDB:
# - Creating a table
# - Writing data to the table
# - Reading data from the table
# - Updating data in the table
# - Querying data in the table
# - Deleting the table (cleanup)

# Set up logging
LOG_FILE="dynamodb-tutorial-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting DynamoDB Getting Started Tutorial at $(date)"
echo "Logging to $LOG_FILE"

# Function to check for errors in command output
check_error() {
    local output=$1
    local cmd_name=$2
    
    if echo "$output" | grep -i "error" > /dev/null; then
        echo "ERROR detected in $cmd_name command:"
        echo "$output"
        exit 1
    fi
}

# Function to wait for table to be in ACTIVE state
wait_for_table_active() {
    local table_name=$1
    local status=""
    
    echo "Waiting for table $table_name to become ACTIVE..."
    
    while [[ "$status" != "ACTIVE" ]]; do
        sleep 5
        status=$(aws dynamodb describe-table --table-name "$table_name" --query "Table.TableStatus" --output text)
        echo "Current status: $status"
    done
    
    echo "Table $table_name is now ACTIVE"
}

# Track created resources for cleanup
RESOURCES=()

# Step 1: Create a table in DynamoDB
echo "Step 1: Creating Music table in DynamoDB..."

CREATE_TABLE_OUTPUT=$(aws dynamodb create-table \
    --table-name Music \
    --attribute-definitions \
        AttributeName=Artist,AttributeType=S \
        AttributeName=SongTitle,AttributeType=S \
    --key-schema AttributeName=Artist,KeyType=HASH AttributeName=SongTitle,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --table-class STANDARD \
    --tags Key=tutorial,Value=amazon-dynamodb-gs)

check_error "$CREATE_TABLE_OUTPUT" "create-table"
echo "$CREATE_TABLE_OUTPUT"

# Add table to resources list
RESOURCES+=("Table:Music")

# Wait for table to be active
wait_for_table_active "Music"

# Enable point-in-time recovery (best practice)
echo "Enabling point-in-time recovery for the Music table..."

PITR_OUTPUT=$(aws dynamodb update-continuous-backups \
    --table-name Music \
    --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true)

check_error "$PITR_OUTPUT" "update-continuous-backups"
echo "$PITR_OUTPUT"

# Step 2: Write data to the DynamoDB table
echo "Step 2: Writing data to the Music table..."

# Add first item
ITEM1_OUTPUT=$(aws dynamodb put-item \
    --table-name Music \
    --item \
        '{"Artist": {"S": "No One You Know"}, "SongTitle": {"S": "Call Me Today"}, "AlbumTitle": {"S": "Somewhat Famous"}, "Awards": {"N": "1"}}')

check_error "$ITEM1_OUTPUT" "put-item (item 1)"
echo "$ITEM1_OUTPUT"

# Add second item
ITEM2_OUTPUT=$(aws dynamodb put-item \
    --table-name Music \
    --item \
        '{"Artist": {"S": "No One You Know"}, "SongTitle": {"S": "Howdy"}, "AlbumTitle": {"S": "Somewhat Famous"}, "Awards": {"N": "2"}}')

check_error "$ITEM2_OUTPUT" "put-item (item 2)"
echo "$ITEM2_OUTPUT"

# Add third item
ITEM3_OUTPUT=$(aws dynamodb put-item \
    --table-name Music \
    --item \
        '{"Artist": {"S": "Acme Band"}, "SongTitle": {"S": "Happy Day"}, "AlbumTitle": {"S": "Songs About Life"}, "Awards": {"N": "10"}}')

check_error "$ITEM3_OUTPUT" "put-item (item 3)"
echo "$ITEM3_OUTPUT"

# Add fourth item
ITEM4_OUTPUT=$(aws dynamodb put-item \
    --table-name Music \
    --item \
        '{"Artist": {"S": "Acme Band"}, "SongTitle": {"S": "PartiQL Rocks"}, "AlbumTitle": {"S": "Another Album Title"}, "Awards": {"N": "8"}}')

check_error "$ITEM4_OUTPUT" "put-item (item 4)"
echo "$ITEM4_OUTPUT"

# Step 3: Read data from the DynamoDB table
echo "Step 3: Reading data from the Music table..."

# Get a specific item
GET_ITEM_OUTPUT=$(aws dynamodb get-item --consistent-read \
    --table-name Music \
    --key '{"Artist": {"S": "Acme Band"}, "SongTitle": {"S": "Happy Day"}}')

check_error "$GET_ITEM_OUTPUT" "get-item"
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
    --return-values ALL_NEW)

check_error "$UPDATE_ITEM_OUTPUT" "update-item"
echo "Updated item:"
echo "$UPDATE_ITEM_OUTPUT"

# Step 5: Query data in the DynamoDB table
echo "Step 5: Querying data in the Music table..."

# Query items by Artist
QUERY_OUTPUT=$(aws dynamodb query \
    --table-name Music \
    --key-condition-expression "Artist = :name" \
    --expression-attribute-values '{":name": {"S": "Acme Band"}}')

check_error "$QUERY_OUTPUT" "query"
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
if [ -t 0 ]; then
    read -rp "Do you want to clean up all created resources? (y/n): " CLEANUP_CHOICE
else
    CLEANUP_CHOICE=y
fi

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    # Step 6: Delete the DynamoDB table
    echo "Step 6: Deleting the Music table..."
    
    DELETE_TABLE_OUTPUT=$(aws dynamodb delete-table --table-name Music)
    
    check_error "$DELETE_TABLE_OUTPUT" "delete-table"
    echo "$DELETE_TABLE_OUTPUT"
    
    echo "Waiting for table deletion to complete..."
    aws dynamodb wait table-not-exists --table-name Music
    
    echo "Cleanup completed successfully."
else
    echo "Skipping cleanup. Resources will remain in your AWS account."
fi

echo "DynamoDB Getting Started Tutorial completed at $(date)"
echo "Log file: $LOG_FILE"