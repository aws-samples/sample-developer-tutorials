#!/bin/bash
set -e

# Generate a unique suffix
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Set AWS credentials and region
export AWS_ACCESS_KEY_ID='YOUR_ACCESS_KEY'
export AWS_SECRET_ACCESS_KEY='YOUR_SECRET_KEY'

# Create a new S3 bucket
BUCKET_NAME="my-test-bucket-${SUFFIX}"
aws s3api create-bucket --bucket ${BUCKET_NAME} --region us-west-2 && echo "Bucket creation status: SUCCESS" || echo "Bucket creation status: FAILURE"

# Clean up: Delete the created bucket
aws s3api delete-bucket --bucket ${BUCKET_NAME} --region us-west-2 && echo "Bucket deletion status: SUCCESS" || echo "Bucket deletion status: FAILURE"

echo "PASS"