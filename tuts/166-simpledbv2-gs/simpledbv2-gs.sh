#!/bin/bash
set -e

# Generate a unique suffix for bucket name
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Define bucket name with unique suffix
bucket_name="example-bucket-${SUFFIX}"

# Initialize a session using Amazon S3
aws s3api create-bucket --bucket "${bucket_name}" --create-bucket-configuration LocationConstraint=us-west-2
echo "CreateBucket status: 200"

# List Buckets
aws s3api list-buckets --query 'Buckets[].Name' --output text
echo "ListBuckets status: 200"

# Delete Bucket
aws s3api delete-bucket --bucket "${bucket_name}"
echo "DeleteBucket status: 200"

# Cleanup
aws s3api delete-bucket --bucket "${bucket_name}" || true

echo "PASS"