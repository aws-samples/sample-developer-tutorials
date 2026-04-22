#!/bin/bash
# S3 Getting Started - Create a bucket, upload and download objects, copy to a
# folder prefix, enable versioning, configure encryption and public access
# blocking, tag the bucket, list objects and versions, and clean up.

set -eE

# ============================================================================
# Prerequisites check
# ============================================================================

CONFIGURED_REGION=$(aws configure get region 2>/dev/null || true)
if [ -z "$CONFIGURED_REGION" ] && [ -z "$AWS_DEFAULT_REGION" ] && [ -z "$AWS_REGION" ]; then
    echo "ERROR: No AWS region configured. Run 'aws configure' or set AWS_DEFAULT_REGION."
    exit 1
fi

# ============================================================================
# Setup: logging, temp directory, resource tracking
# ============================================================================

UNIQUE_ID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 12 | head -n 1)
# Check for shared prereq bucket
PREREQ_BUCKET=$(aws cloudformation describe-stacks --stack-name tutorial-prereqs-bucket \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text 2>/dev/null)
if [ -n "$PREREQ_BUCKET" ] && [ "$PREREQ_BUCKET" != "None" ]; then
    BUCKET_NAME="$PREREQ_BUCKET"
    BUCKET_IS_SHARED=true
    echo "Using shared bucket: $BUCKET_NAME"
else
    BUCKET_IS_SHARED=false
    BUCKET_NAME="s3api-${UNIQUE_ID}"
fi

TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/s3-gettingstarted.log"
CREATED_RESOURCES=()

exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================"
echo "S3 Getting Started"
echo "============================================"
echo "Bucket name: ${BUCKET_NAME}"
echo "Temp directory: ${TEMP_DIR}"
echo "Log file: ${LOG_FILE}"
echo ""

# ============================================================================
# Error handling and cleanup functions
# ============================================================================

cleanup() {
    echo ""
    echo "============================================"
    echo "CLEANUP"
    echo "============================================"

    # Delete all object versions and delete markers
    echo "Listing all object versions in bucket..."
    VERSIONS_OUTPUT=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --query "Versions[].{Key:Key,VersionId:VersionId}" \
        --output text 2>&1) || true

    if [ -n "$VERSIONS_OUTPUT" ] && [ "$VERSIONS_OUTPUT" != "None" ]; then
        while IFS=$'\t' read -r KEY VERSION_ID; do
            if [ -n "$KEY" ] && [ "$KEY" != "None" ]; then
                echo "Deleting version: ${KEY} (${VERSION_ID})"
                aws s3api delete-object \
                    --bucket "$BUCKET_NAME" \
                    --key "$KEY" \
                    --version-id "$VERSION_ID" 2>&1 || echo "WARNING: Failed to delete version ${KEY} (${VERSION_ID})"
            fi
        done <<< "$VERSIONS_OUTPUT"
    fi

    DELETE_MARKERS_OUTPUT=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --query "DeleteMarkers[].{Key:Key,VersionId:VersionId}" \
        --output text 2>&1) || true

    if [ -n "$DELETE_MARKERS_OUTPUT" ] && [ "$DELETE_MARKERS_OUTPUT" != "None" ]; then
        while IFS=$'\t' read -r KEY VERSION_ID; do
            if [ -n "$KEY" ] && [ "$KEY" != "None" ]; then
                echo "Deleting delete marker: ${KEY} (${VERSION_ID})"
                aws s3api delete-object \
                    --bucket "$BUCKET_NAME" \
                    --key "$KEY" \
                    --version-id "$VERSION_ID" 2>&1 || echo "WARNING: Failed to delete marker ${KEY} (${VERSION_ID})"
            fi
        done <<< "$DELETE_MARKERS_OUTPUT"
    fi

    echo "Deleting bucket: ${BUCKET_NAME}"
    if [ "$BUCKET_IS_SHARED" = "false" ]; then
        aws s3api delete-bucket --bucket "$BUCKET_NAME" 2>&1 || echo "WARNING: Failed to delete bucket ${BUCKET_NAME}"
    fi

    echo ""
    echo "Cleaning up temp directory: ${TEMP_DIR}"
    rm -rf "$TEMP_DIR"

    echo ""
    echo "Cleanup complete."
}

handle_error() {
    echo ""
    echo "============================================"
    echo "ERROR on $1"
    echo "============================================"
    echo ""
    echo "Resources created before error:"
    for RESOURCE in "${CREATED_RESOURCES[@]}"; do
        echo "  - ${RESOURCE}"
    done
    echo ""
    echo "Attempting cleanup..."
    cleanup
    exit 1
}

trap 'handle_error "line $LINENO"' ERR

# ============================================================================
# Step 1: Create a bucket
# ============================================================================

echo "Step 1: Creating bucket ${BUCKET_NAME}..."

# CreateBucket requires LocationConstraint for all regions except us-east-1
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-${CONFIGURED_REGION}}}"
if [ "$REGION" = "us-east-1" ]; then
    CREATE_OUTPUT=$(aws s3api create-bucket \
        --bucket "$BUCKET_NAME" 2>&1)
else
    CREATE_OUTPUT=$(aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint="$REGION" 2>&1)
fi
echo "$CREATE_OUTPUT"
CREATED_RESOURCES+=("s3:bucket:${BUCKET_NAME}")
echo "Bucket created."
echo ""

# ============================================================================
# Step 2: Upload a sample text file
# ============================================================================

echo "Step 2: Uploading a sample text file..."

SAMPLE_FILE="${TEMP_DIR}/sample.txt"
echo "Hello, Amazon S3! This is a sample file for the getting started tutorial." > "$SAMPLE_FILE"

UPLOAD_OUTPUT=$(aws s3api put-object \
    --bucket "$BUCKET_NAME" \
    --key "sample.txt" \
    --body "$SAMPLE_FILE" 2>&1)
echo "$UPLOAD_OUTPUT"
echo "File uploaded."
echo ""

# ============================================================================
# Step 3: Download the object
# ============================================================================

echo "Step 3: Downloading the object..."

DOWNLOAD_FILE="${TEMP_DIR}/downloaded-sample.txt"
aws s3api get-object \
    --bucket "$BUCKET_NAME" \
    --key "sample.txt" \
    "$DOWNLOAD_FILE" 2>&1
echo "Downloaded to: ${DOWNLOAD_FILE}"
echo "Contents:"
cat "$DOWNLOAD_FILE"
echo ""

# ============================================================================
# Step 4: Copy the object to a folder prefix
# ============================================================================

echo "Step 4: Copying object to a folder prefix..."

COPY_OUTPUT=$(aws s3api copy-object \
    --bucket "$BUCKET_NAME" \
    --copy-source "${BUCKET_NAME}/sample.txt" \
    --key "backup/sample.txt" 2>&1)
echo "$COPY_OUTPUT"
echo "Object copied to backup/sample.txt."
echo ""

# ============================================================================
# Step 5: Enable versioning and upload a second version
# ============================================================================

echo "Step 5: Enabling versioning..."

VERSIONING_OUTPUT=$(aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled 2>&1)
echo "$VERSIONING_OUTPUT"
echo "Versioning enabled."

echo "Uploading a second version of sample.txt..."
echo "Hello, Amazon S3! This is version 2 of the sample file." > "$SAMPLE_FILE"

UPLOAD_V2_OUTPUT=$(aws s3api put-object \
    --bucket "$BUCKET_NAME" \
    --key "sample.txt" \
    --body "$SAMPLE_FILE" 2>&1)
echo "$UPLOAD_V2_OUTPUT"
echo "Second version uploaded."
echo ""

# ============================================================================
# Step 6: Configure SSE-S3 encryption
# ============================================================================

echo "Step 6: Configuring SSE-S3 default encryption..."

ENCRYPTION_OUTPUT=$(aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }' 2>&1)
echo "$ENCRYPTION_OUTPUT"
echo "SSE-S3 encryption configured."
echo ""

# ============================================================================
# Step 7: Block all public access
# ============================================================================

echo "Step 7: Blocking all public access..."

PUBLIC_ACCESS_OUTPUT=$(aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }' 2>&1)
echo "$PUBLIC_ACCESS_OUTPUT"
echo "Public access blocked."
echo ""

# ============================================================================
# Step 8: Tag the bucket
# ============================================================================

echo "Step 8: Tagging the bucket..."

TAG_OUTPUT=$(aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging '{
        "TagSet": [
            {
                "Key": "Environment",
                "Value": "Tutorial"
            },
            {
                "Key": "Project",
                "Value": "S3-GettingStarted"
            }
        ]
    }' 2>&1)
echo "$TAG_OUTPUT"
echo "Bucket tagged."

echo "Verifying tags..."
GET_TAGS_OUTPUT=$(aws s3api get-bucket-tagging \
    --bucket "$BUCKET_NAME" 2>&1)
echo "$GET_TAGS_OUTPUT"
echo ""

# ============================================================================
# Step 9: List objects and versions
# ============================================================================

echo "Step 9: Listing objects..."

LIST_OUTPUT=$(aws s3api list-objects-v2 \
    --bucket "$BUCKET_NAME" 2>&1)
echo "$LIST_OUTPUT"
echo ""

echo "Listing object versions..."

VERSIONS_LIST=$(aws s3api list-object-versions \
    --bucket "$BUCKET_NAME" 2>&1)
echo "$VERSIONS_LIST"
echo ""

# ============================================================================
# Step 10: Cleanup
# ============================================================================

echo ""
echo "============================================"
echo "TUTORIAL COMPLETE"
echo "============================================"
echo ""
echo "Resources created:"
for RESOURCE in "${CREATED_RESOURCES[@]}"; do
    echo "  - ${RESOURCE}"
done
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo ""
    echo "Resources were NOT deleted. To clean up manually, run:"
    echo ""
    echo "  # Delete all object versions"
    echo "  aws s3api list-object-versions --bucket ${BUCKET_NAME} --query 'Versions[].{Key:Key,VersionId:VersionId}' --output text | while IFS=\$'\\t' read -r KEY VID; do aws s3api delete-object --bucket ${BUCKET_NAME} --key \"\$KEY\" --version-id \"\$VID\"; done"
    echo ""
    echo "  # Delete all delete markers"
    echo "  aws s3api list-object-versions --bucket ${BUCKET_NAME} --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output text | while IFS=\$'\\t' read -r KEY VID; do aws s3api delete-object --bucket ${BUCKET_NAME} --key \"\$KEY\" --version-id \"\$VID\"; done"
    echo ""
    echo "  # Delete the bucket"
    echo "  aws s3api delete-bucket --bucket ${BUCKET_NAME}"
    echo ""
    echo "  # Remove temp directory"
    echo "  rm -rf ${TEMP_DIR}"
fi

echo ""
echo "Done."
