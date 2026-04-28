#!/bin/bash

# AWS Glue Data Catalog Tutorial Script
# This script demonstrates how to create and manage AWS Glue Data Catalog resources using the AWS CLI

set -euo pipefail

# Setup logging
LOG_FILE="glue-tutorial-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting AWS Glue Data Catalog tutorial script at $(date)"
echo "All operations will be logged to $LOG_FILE"

# Validate AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed. Exiting."
    exit 1
fi

# Validate AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS credentials are not configured. Exiting."
    exit 1
fi

# Get AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

if [[ -z "$AWS_ACCOUNT_ID" ]] || [[ -z "$AWS_REGION" ]]; then
    echo "ERROR: Unable to retrieve AWS account ID or region. Exiting."
    exit 1
fi

# Generate a unique identifier for resource names
UNIQUE_ID=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 8)
DB_NAME="tutorial-db-${UNIQUE_ID}"
TABLE_NAME="flights-data-${UNIQUE_ID}"

# Track created resources
CREATED_RESOURCES=()

# Trap errors and cleanup
trap 'cleanup_resources' EXIT

# Function to check command status
check_status() {
    if [ $? -ne 0 ]; then
        echo "ERROR: $1 failed. Exiting."
        exit 1
    fi
}

# Function to cleanup resources
cleanup_resources() {
    local exit_code=$?
    
    if [[ ${#CREATED_RESOURCES[@]} -eq 0 ]]; then
        return $exit_code
    fi
    
    echo "Attempting to clean up resources..."
    
    # Delete resources in reverse order
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        resource=${CREATED_RESOURCES[$i]}
        resource_type=$(echo "$resource" | cut -d':' -f1)
        resource_name=$(echo "$resource" | cut -d':' -f2)
        
        echo "Deleting $resource_type: $resource_name"
        
        case $resource_type in
            "table")
                if aws glue delete-table --database-name "$DB_NAME" --name "$resource_name" 2>/dev/null; then
                    echo "Successfully deleted table: $resource_name"
                else
                    echo "WARNING: Failed to delete table: $resource_name"
                fi
                ;;
            "database")
                if aws glue delete-database --name "$resource_name" 2>/dev/null; then
                    echo "Successfully deleted database: $resource_name"
                else
                    echo "WARNING: Failed to delete database: $resource_name"
                fi
                ;;
            *)
                echo "Unknown resource type: $resource_type"
                ;;
        esac
    done
    
    echo "Cleanup completed."
    return $exit_code
}

# Step 1: Create a database
echo "Step 1: Creating a database named $DB_NAME"
aws glue create-database --database-input "Name=$DB_NAME,Description=Database for AWS Glue tutorial" --region "$AWS_REGION" > /dev/null
check_status "Creating database"

aws glue tag-resource --resource-arn "arn:aws:glue:${AWS_REGION}:${AWS_ACCOUNT_ID}:database/${DB_NAME}" --tags-to-add "project=doc-smith" "tutorial=glue-gs" --region "$AWS_REGION" > /dev/null
check_status "Tagging database"

CREATED_RESOURCES+=("database:$DB_NAME")
echo "Database $DB_NAME created successfully."

# Verify the database was created
echo "Verifying database creation..."
DB_VERIFY=$(aws glue get-database --name "$DB_NAME" --query 'Database.Name' --output text --region "$AWS_REGION")
check_status "Verifying database"

if [ "$DB_VERIFY" != "$DB_NAME" ]; then
    echo "ERROR: Database verification failed. Expected $DB_NAME but got $DB_VERIFY"
    exit 1
fi
echo "Database verification successful."

# Step 2: Create a table
echo "Step 2: Creating a table named $TABLE_NAME in database $DB_NAME"

# Create a temporary JSON file for table input
TABLE_INPUT_FILE=$(mktemp -t glue-table-input-XXXXXX.json)
trap "rm -f '$TABLE_INPUT_FILE'" RETURN

cat > "$TABLE_INPUT_FILE" << 'EOF'
{
  "Name": "PLACEHOLDER_TABLE_NAME",
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

# Replace placeholder with actual table name using sed
sed -i.bak "s/PLACEHOLDER_TABLE_NAME/$TABLE_NAME/g" "$TABLE_INPUT_FILE"
rm -f "${TABLE_INPUT_FILE}.bak"

aws glue create-table --database-name "$DB_NAME" --table-input "file://${TABLE_INPUT_FILE}" --region "$AWS_REGION" > /dev/null
check_status "Creating table"

aws glue tag-resource --resource-arn "arn:aws:glue:${AWS_REGION}:${AWS_ACCOUNT_ID}:table/${DB_NAME}/${TABLE_NAME}" --tags-to-add "project=doc-smith" "tutorial=glue-gs" --region "$AWS_REGION" > /dev/null
check_status "Tagging table"

CREATED_RESOURCES+=("table:$TABLE_NAME")
echo "Table $TABLE_NAME created successfully."

# Verify the table was created
echo "Verifying table creation..."
TABLE_VERIFY=$(aws glue get-table --database-name "$DB_NAME" --name "$TABLE_NAME" --query 'Table.Name' --output text --region "$AWS_REGION")
check_status "Verifying table"

if [ "$TABLE_VERIFY" != "$TABLE_NAME" ]; then
    echo "ERROR: Table verification failed. Expected $TABLE_NAME but got $TABLE_VERIFY"
    exit 1
fi
echo "Table verification successful."

# Step 3: Get table details
echo "Step 3: Getting details of table $TABLE_NAME"
aws glue get-table --database-name "$DB_NAME" --name "$TABLE_NAME" --region "$AWS_REGION"
check_status "Getting table details"

# Display created resources
echo ""
echo "==========================================="
echo "RESOURCES CREATED"
echo "==========================================="
echo "Database: $DB_NAME"
echo "Table: $TABLE_NAME"
echo "==========================================="

# Prompt for cleanup with timeout
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "

if read -r -t 30 CLEANUP_CHOICE; then
    if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
        echo "Starting cleanup process..."
        CREATED_RESOURCES_BACKUP=("${CREATED_RESOURCES[@]}")
        CREATED_RESOURCES=()
        for resource in "${CREATED_RESOURCES_BACKUP[@]}"; do
            resource_type=$(echo "$resource" | cut -d':' -f1)
            resource_name=$(echo "$resource" | cut -d':' -f2)
            
            echo "Deleting $resource_type: $resource_name"
            
            case $resource_type in
                "table")
                    aws glue delete-table --database-name "$DB_NAME" --name "$resource_name" --region "$AWS_REGION" > /dev/null 2>&1 || echo "WARNING: Failed to delete table"
                    ;;
                "database")
                    aws glue delete-database --name "$resource_name" --region "$AWS_REGION" > /dev/null 2>&1 || echo "WARNING: Failed to delete database"
                    ;;
            esac
        done
    else
        echo "Skipping cleanup. Resources will remain in your account."
        echo "To clean up manually, run the following commands:"
        echo "aws glue delete-table --database-name $DB_NAME --name $TABLE_NAME --region $AWS_REGION"
        echo "aws glue delete-database --name $DB_NAME --region $AWS_REGION"
    fi
else
    echo ""
    echo "Timeout reached. Skipping cleanup. Resources will remain in your account."
    echo "To clean up manually, run the following commands:"
    echo "aws glue delete-table --database-name $DB_NAME --name $TABLE_NAME --region $AWS_REGION"
    echo "aws glue delete-database --name $DB_NAME --region $AWS_REGION"
fi

echo "Script completed at $(date)"