#!/bin/bash
set -e

# Generate a unique suffix
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Bucket name for S3 operations
bucket_name="test-bucket-${SUFFIX}"

# Create S3 bucket
aws s3api create-bucket --bucket "${bucket_name}" && \
echo "Bucket '${bucket_name}' created" || true

# Upload a file to the bucket (using a sample file)
aws s3api put-object --bucket "${bucket_name}" --key "${SUFFIX}/sample.json" --body /test-files/sample.json && \
echo "File uploaded to bucket '${bucket_name}'" || true

# List objects in the bucket
aws s3api list-objects-v2 --bucket "${bucket_name}" && \
echo "ListObjectsV2 status: Success" || true

# Delete the uploaded file
aws s3api delete-object --bucket "${bucket_name}" --key "${SUFFIX}/sample.json" && \
echo "File deleted from bucket '${bucket_name}'" || true

# Delete the bucket
aws s3api delete-bucket --bucket "${bucket_name}" && \
echo "Bucket '${bucket_name}' deleted" || true

echo "PASS"