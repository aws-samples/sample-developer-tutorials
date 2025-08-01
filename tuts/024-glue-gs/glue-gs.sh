#!/bin/bash

# AWS Glue Data Catalog Tutorial Script
# This script demonstrates how to create and manage AWS Glue Data Catalog resources using the AWS CLI

# Setup logging
LOG_FILE="glue-tutorial-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting AWS Glue Data Catalog tutorial script at $(date)"
echo "All operations will be logged to $LOG_FILE"

# Generate a unique identifier for resource names
UNIQUE_ID=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 8)
DB_NAME="tutorial-db-${UNIQUE_ID}"
TABLE_NAME="flights-data-${UNIQUE_ID}"

# Track created resources
CREATED_RESOURCES=()

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
    
    # Delete resources in reverse order
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        resource=${CREATED_RESOURCES[$i]}
        resource_type=$(echo "$resource" | cut -d':' -f1)
        resource_name=$(echo "$resource" | cut -d':' -f2)
        
        echo "Deleting $resource_type: $resource_name"
        
        case $resource_type in
            "table")
                aws glue delete-table --database-name "$DB_NAME" --name "$resource_name"
                ;;
            "database")
                aws glue delete-database --name "$resource_name"
                ;;
            *)
                echo "Unknown resource type: $resource_type"
                ;;
        esac
    done
    
    echo "Cleanup completed."
}

# Step 1: Create a database
echo "Step 1: Creating a database named $DB_NAME"
aws glue create-database --database-input "{\"Name\":\"$DB_NAME\",\"Description\":\"Database for AWS Glue tutorial\"}"
check_status "Creating database"
CREATED_RESOURCES+=("database:$DB_NAME")
echo "Database $DB_NAME created successfully."

# Verify the database was created
echo "Verifying database creation..."
DB_VERIFY=$(aws glue get-database --name "$DB_NAME" --query 'Database.Name' --output text)
check_status "Verifying database"

if [ "$DB_VERIFY" != "$DB_NAME" ]; then
    echo "ERROR: Database verification failed. Expected $DB_NAME but got $DB_VERIFY"
    cleanup_resources
    exit 1
fi
echo "Database verification successful."

# Step 2: Create a table
echo "Step 2: Creating a table named $TABLE_NAME in database $DB_NAME"

# Create a temporary JSON file for table input
TABLE_INPUT_FILE="table-input-${UNIQUE_ID}.json"
cat > "$TABLE_INPUT_FILE" << EOF
{
  "Name": "$TABLE_NAME",
  "StorageDescriptor": {
    "Columns": [
      {
        "Name": "year",
        "Type": "bigint"
      },
      {
        "Name": "quarter",
        "Type": "bigint"
      }
    ],
    "Location": "s3://crawler-public-us-west-2/flight/2016/csv",
    "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
    "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
    "Compressed": false,
    "NumberOfBuckets": -1,
    "SerdeInfo": {
      "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
      "Parameters": {
        "field.delim": ",",
        "serialization.format": ","
      }
    }
  },
  "PartitionKeys": [
    {
      "Name": "mon",
      "Type": "string"
    }
  ],
  "TableType": "EXTERNAL_TABLE",
  "Parameters": {
    "EXTERNAL": "TRUE",
    "classification": "csv",
    "columnsOrdered": "true",
    "compressionType": "none",
    "delimiter": ",",
    "skip.header.line.count": "1",
    "typeOfData": "file"
  }
}
EOF

aws glue create-table --database-name "$DB_NAME" --table-input file://"$TABLE_INPUT_FILE"
check_status "Creating table"
CREATED_RESOURCES+=("table:$TABLE_NAME")
echo "Table $TABLE_NAME created successfully."

# Clean up the temporary file
rm -f "$TABLE_INPUT_FILE"

# Verify the table was created
echo "Verifying table creation..."
TABLE_VERIFY=$(aws glue get-table --database-name "$DB_NAME" --name "$TABLE_NAME" --query 'Table.Name' --output text)
check_status "Verifying table"

if [ "$TABLE_VERIFY" != "$TABLE_NAME" ]; then
    echo "ERROR: Table verification failed. Expected $TABLE_NAME but got $TABLE_VERIFY"
    cleanup_resources
    exit 1
fi
echo "Table verification successful."

# Step 3: Get table details
echo "Step 3: Getting details of table $TABLE_NAME"
aws glue get-table --database-name "$DB_NAME" --name "$TABLE_NAME"
check_status "Getting table details"

# Display created resources
echo ""
echo "==========================================="
echo "RESOURCES CREATED"
echo "==========================================="
echo "Database: $DB_NAME"
echo "Table: $TABLE_NAME"
echo "==========================================="

# Prompt for cleanup
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy] ]]; then
    echo "Starting cleanup process..."
    cleanup_resources
else
    echo "Skipping cleanup. Resources will remain in your account."
    echo "To clean up manually, run the following commands:"
    echo "aws glue delete-table --database-name $DB_NAME --name $TABLE_NAME"
    echo "aws glue delete-database --name $DB_NAME"
fi

echo "Script completed at $(date)"
