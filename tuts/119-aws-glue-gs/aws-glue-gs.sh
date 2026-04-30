#!/bin/bash
# Tutorial: Create a Glue Data Catalog database and table
# Source: https://docs.aws.amazon.com/glue/latest/dg/getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/glue-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
DB_NAME="tut_db_${RANDOM_ID}"
TABLE_NAME="tut_events"
BUCKET_NAME="glue-tut-${RANDOM_ID}-${ACCOUNT_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws glue delete-table --database-name "$DB_NAME" --name "$TABLE_NAME" 2>/dev/null && echo "  Deleted table $TABLE_NAME"
    aws glue delete-database --name "$DB_NAME" 2>/dev/null && echo "  Deleted database $DB_NAME"
    if aws s3 ls "s3://$BUCKET_NAME" > /dev/null 2>&1; then
        aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet 2>/dev/null
        aws s3 rb "s3://$BUCKET_NAME" 2>/dev/null && echo "  Deleted bucket $BUCKET_NAME"
    fi
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a database
echo "Step 1: Creating Glue database: $DB_NAME"
aws glue create-database --database-input "{\"Name\":\"$DB_NAME\",\"Description\":\"Tutorial database for event data\"}"
echo "  Database created"

# Step 2: Create an S3 bucket for data
echo "Step 2: Creating S3 bucket for data: $BUCKET_NAME"
if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" > /dev/null
else
    aws s3api create-bucket --bucket "$BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint="$REGION" > /dev/null
fi

# Upload sample data
echo '{"event_id":"e001","event_type":"click","timestamp":"2026-04-14T10:00:00Z","user_id":"u123"}
{"event_id":"e002","event_type":"view","timestamp":"2026-04-14T10:01:00Z","user_id":"u456"}
{"event_id":"e003","event_type":"purchase","timestamp":"2026-04-14T10:02:00Z","user_id":"u123"}' > "$WORK_DIR/events.jsonl"
aws s3 cp "$WORK_DIR/events.jsonl" "s3://$BUCKET_NAME/events/events.jsonl" --quiet
echo "  Uploaded sample data (3 events)"

# Step 3: Create a table
echo "Step 3: Creating table: $TABLE_NAME"
aws glue create-table --database-name "$DB_NAME" --table-input "{
    \"Name\":\"$TABLE_NAME\",
    \"StorageDescriptor\":{
        \"Columns\":[
            {\"Name\":\"event_id\",\"Type\":\"string\"},
            {\"Name\":\"event_type\",\"Type\":\"string\"},
            {\"Name\":\"timestamp\",\"Type\":\"string\"},
            {\"Name\":\"user_id\",\"Type\":\"string\"}
        ],
        \"Location\":\"s3://$BUCKET_NAME/events/\",
        \"InputFormat\":\"org.apache.hadoop.mapred.TextInputFormat\",
        \"OutputFormat\":\"org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat\",
        \"SerdeInfo\":{\"SerializationLibrary\":\"org.openx.data.jsonserde.JsonSerDe\"}
    },
    \"TableType\":\"EXTERNAL_TABLE\"
}"
echo "  Table created (JSON SerDe, external)"

# Step 4: Describe the table
echo "Step 4: Table details"
aws glue get-table --database-name "$DB_NAME" --name "$TABLE_NAME" \
    --query 'Table.{Name:Name,Database:DatabaseName,Location:StorageDescriptor.Location,Columns:StorageDescriptor.Columns|length(@)}' --output table

# Step 5: List databases and tables
echo "Step 5: Listing databases"
aws glue get-databases --query 'DatabaseList[?starts_with(Name, `tut_`)].{Name:Name,Description:Description}' --output table

echo "Step 5b: Listing tables in $DB_NAME"
aws glue get-tables --database-name "$DB_NAME" \
    --query 'TableList[].{Name:Name,Type:TableType,Columns:StorageDescriptor.Columns|length(@)}' --output table

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws glue delete-table --database-name $DB_NAME --name $TABLE_NAME"
    echo "  aws glue delete-database --name $DB_NAME"
    echo "  aws s3 rm s3://$BUCKET_NAME --recursive && aws s3 rb s3://$BUCKET_NAME"
fi
