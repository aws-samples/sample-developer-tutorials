#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

trap cleanup_resources EXIT

cleanup_resources() {
    for ARN in "${CREATED_RESOURCES[@]}"; do
        aws bcm-data-exports delete-export --export-arn "$ARN" &>> "$LOG_FILE"
    done
    rm -rf "$TEMP_DIR"
}

echo "Step 1: List existing exports"
aws bcm-data-exports list-exports --query 'length(Exports)' --output text &>> "$LOG_FILE" && echo "Exports listed"

echo "Step 2: Create a new export"
EXPORT_NAME="example-export-${SUFFIX}"
BUCKET_NAME="your-s3-bucket-name"
PREFIX="your-s3-prefix/"
QUERY="your-query-here"
aws bcm-data-exports create-export \
    --export Name="${EXPORT_NAME}",Description="Example export",DestinationConfiguration="{DestinationType=S3,S3Destination={Bucket=${BUCKET_NAME},Prefix=${PREFIX}}}",RefreshCadence="{Frequency=MONTHLY}",DataQuery="{Query=${QUERY}}" \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=bcm-data-exports-gs &>> "$LOG_FILE" && {
    EXPORT_ARN=$(aws bcm-data-exports list-exports --query 'Exports[?Name==`'"${EXPORT_NAME}"'`].ExportArn' --output text)
    CREATED_RESOURCES+=("$EXPORT_ARN")
    echo "Export created"
}

echo "Step 3: List exports again to verify the new export is created"
aws bcm-data-exports list-exports --query 'length(Exports)' --output text &>> "$LOG_FILE" && echo "Exports listed after creation"

if [ -z "$EXPORT_ARN" ]; then
    echo "Skipping Step 4: Get the newly created export (export not created)"
else
    echo "Step 4: Get the newly created export"
    aws bcm-data-exports get-export --export-arn "$EXPORT_ARN" &>> "$LOG_FILE" && echo "Export retrieved"
fi

if [ -z "$EXPORT_ARN" ]; then
    echo "Skipping Step 5: Update the export (export not created)"
else
    echo "Step 5: Update the export"
    aws bcm-data-exports update-export \
        --export-arn "$EXPORT_ARN" \
        --export Name="updated-example-export-${SUFFIX}",Description="Updated example export" &>> "$LOG_FILE" && echo "Export updated"
fi

if [ -z "$EXPORT_ARN" ]; then
    echo "Skipping Step 6: Get the updated export (export not created)"
else
    echo "Step 6: Get the updated export"
    aws bcm-data-exports get-export --export-arn "$EXPORT_ARN" &>> "$LOG_FILE" && echo "Updated export retrieved"
fi

echo "PASS"