#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
EXPORT_NAME="example-export-${SUFFIX}"
BUCKET_NAME="your-s3-bucket-name"
PREFIX="your-s3-prefix/"
QUERY="your-query-here"
EXPORT_ARN="arn:aws:bcm-data-exports:us-east-1:123456789012:export/${EXPORT_NAME}"

# List existing exports
aws bcm-data-exports list-exports --query 'length(Exports)' --output text && echo "Exports listed"

# Create a new export
aws bcm-data-exports create-export \
    --export Name="${EXPORT_NAME}",Description="This is an example export for getting started with bcm-data-exports",DestinationConfiguration="{DestinationType=S3,S3Destination={Bucket=${BUCKET_NAME},Prefix=${PREFIX}}}",RefreshCadence="{Frequency=MONTHLY}",DataQuery="{Query=${QUERY}}" && echo "Export created"

# List exports again to verify the new export is created
aws bcm-data-exports list-exports --query 'length(Exports)' --output text && echo "Exports listed after creation"

# Get the newly created export
aws bcm-data-exports get-export --export-arn ${EXPORT_ARN} && echo "Export retrieved"

# Update the export
aws bcm-data-exports update-export \
    --export-arn ${EXPORT_ARN} \
    --export Name="updated-example-export-${SUFFIX}",Description="Updated example export for getting started with bcm-data-exports" && echo "Export updated"

# Get the updated export
aws bcm-data-exports get-export --export-arn ${EXPORT_ARN} && echo "Updated export retrieved"

# Delete the export
aws bcm-data-exports delete-export --export-arn ${EXPORT_ARN} && echo "Export deleted"

# List exports to verify the export is deleted
aws bcm-data-exports list-exports --query 'length(Exports)' --output text && echo "Exports listed after deletion"

echo "PASS"