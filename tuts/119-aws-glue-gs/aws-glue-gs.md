# Create a Data Catalog database and table with AWS Glue

## Overview

In this tutorial, you use the AWS CLI to create an AWS Glue Data Catalog database, upload sample JSON event data to S3, create an external table that points to the data, and query the catalog. You then delete all resources during cleanup.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- An IAM principal with permissions for `glue:CreateDatabase`, `glue:CreateTable`, `glue:GetTable`, `glue:GetDatabases`, `glue:GetTables`, `glue:DeleteTable`, `glue:DeleteDatabase`, `s3:CreateBucket`, `s3:PutObject`, `s3:DeleteObject`, `s3:DeleteBucket`, and `sts:GetCallerIdentity`.

## Step 1: Create a database

Create a Glue Data Catalog database to hold table definitions.

```bash
RANDOM_ID=$(openssl rand -hex 4)
DB_NAME="tut_db_${RANDOM_ID}"

aws glue create-database \
    --database-input "{\"Name\":\"$DB_NAME\",\"Description\":\"Tutorial database for event data\"}"
echo "Database: $DB_NAME"
```

A Glue database is a logical container for tables. It stores metadata only — the actual data lives in S3 or another data store.

## Step 2: Create an S3 bucket and upload sample data

Create a bucket and upload sample JSON Lines event data.

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
BUCKET_NAME="glue-tut-${RANDOM_ID}-${ACCOUNT_ID}"

aws s3api create-bucket --bucket "$BUCKET_NAME"

cat > /tmp/events.jsonl << 'EOF'
{"event_id":"e001","event_type":"click","timestamp":"2026-04-14T10:00:00Z","user_id":"u123"}
{"event_id":"e002","event_type":"view","timestamp":"2026-04-14T10:01:00Z","user_id":"u456"}
{"event_id":"e003","event_type":"purchase","timestamp":"2026-04-14T10:02:00Z","user_id":"u123"}
EOF

aws s3 cp /tmp/events.jsonl "s3://$BUCKET_NAME/events/events.jsonl" --quiet
```

For regions other than `us-east-1`, add `--create-bucket-configuration LocationConstraint=$REGION`.

## Step 3: Create a table

Create an external table that maps the JSON fields to columns using the JSON SerDe.

```bash
TABLE_NAME="tut_events"

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
echo "Table: $TABLE_NAME"
```

`EXTERNAL_TABLE` means Glue doesn't manage the data lifecycle — deleting the table doesn't delete the S3 data. The JSON SerDe deserializes each line as a JSON object.

## Step 4: Describe the table

View the table metadata including column definitions and data location.

```bash
aws glue get-table --database-name "$DB_NAME" --name "$TABLE_NAME" \
    --query 'Table.{Name:Name,Database:DatabaseName,Location:StorageDescriptor.Location,Columns:StorageDescriptor.Columns|length(@)}' \
    --output table
```

## Step 5: List databases and tables

List databases and tables in the catalog.

```bash
aws glue get-databases \
    --query 'DatabaseList[?starts_with(Name, `tut_`)].{Name:Name,Description:Description}' \
    --output table

aws glue get-tables --database-name "$DB_NAME" \
    --query 'TableList[].{Name:Name,Type:TableType,Columns:StorageDescriptor.Columns|length(@)}' \
    --output table
```

## Cleanup

Delete the table, database, and S3 bucket.

```bash
aws glue delete-table --database-name "$DB_NAME" --name "$TABLE_NAME"
aws glue delete-database --name "$DB_NAME"
aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet
aws s3 rb "s3://$BUCKET_NAME"
```

Delete the table before the database. The database cannot be deleted while it contains tables.

The script automates all steps including cleanup:

```bash
bash aws-glue-gs.sh
```

## Related resources

- [Getting started with AWS Glue](https://docs.aws.amazon.com/glue/latest/dg/getting-started.html)
- [Defining databases in the Data Catalog](https://docs.aws.amazon.com/glue/latest/dg/define-database.html)
- [Defining tables in the Data Catalog](https://docs.aws.amazon.com/glue/latest/dg/tables-described.html)
- [AWS Glue pricing](https://aws.amazon.com/glue/pricing/)
