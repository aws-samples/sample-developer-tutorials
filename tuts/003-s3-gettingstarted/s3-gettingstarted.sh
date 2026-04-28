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

# Use secure random generation for unique ID
UNIQUE_ID=$(openssl rand -hex 3 2>/dev/null || head -c 6 /dev/urandom | od -An -tx1 | tr -d ' ')

# Check for shared prereq bucket
PREREQ_BUCKET=$(aws cloudformation describe-stacks --stack-name tutorial-prereqs-bucket \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text 2>/dev/null || true)
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
ERRORS_OCCURRED=0

# Secure temp directory permissions
chmod 700 "$TEMP_DIR"

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

    if [ "$BUCKET_IS_SHARED" = "false" ]; then
        # Delete all object versions and delete markers
        echo "Listing and deleting all object versions in bucket..."
        
        # Check if bucket exists before attempting deletion
        if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
            echo "Bucket ${BUCKET_NAME} does not exist, skipping deletion."
        else
            # Use s3 rm command for efficient bulk deletion with built-in retry logic
            if aws s3 rm "s3://${BUCKET_NAME}" --recursive --quiet 2>/dev/null; then
                echo "Objects deleted successfully."
            else
                echo "WARNING: Some objects may not have been deleted, but continuing with bucket deletion..."
            fi
            
            # Delete the bucket itself with retry logic
            local RETRY_COUNT=0
            local MAX_RETRIES=3
            while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
                if aws s3api delete-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
                    echo "Bucket ${BUCKET_NAME} deleted successfully."
                    break
                else
                    RETRY_COUNT=$((RETRY_COUNT + 1))
                    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                        echo "Retrying bucket deletion (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)..."
                        sleep 2
                    else
                        echo "WARNING: Failed to delete bucket ${BUCKET_NAME} after $MAX_RETRIES attempts"
                    fi
                fi
            done
        fi
    else
        echo "Keeping shared bucket: ${BUCKET_NAME}"
    fi

    echo ""
    echo "Cleaning up temp directory: ${TEMP_DIR}"
    rm -rf "$TEMP_DIR"

    echo ""
    echo "Cleanup complete."
}

handle_error() {
    local ERROR_LINE=$1
    ERRORS_OCCURRED=1
    
    echo ""
    echo "============================================"
    echo "ERROR on ${ERROR_LINE}"
    echo "============================================"
    echo ""
    echo "Resources created before error:"
    if [ ${#CREATED_RESOURCES[@]} -eq 0 ]; then
        echo "  (none)"
    else
        for RESOURCE in "${CREATED_RESOURCES[@]}"; do
            echo "  - ${RESOURCE}"
        done
    fi
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
if [ "$BUCKET_IS_SHARED" = "false" ]; then

REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-${CONFIGURED_REGION}}}"

# Create bucket with appropriate region configuration
if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" 2>&1
else
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION" 2>&1
fi

CREATED_RESOURCES+=("s3:bucket:${BUCKET_NAME}")
echo "Bucket created."

# Apply configurations in parallel for better performance
(
    echo "Tagging bucket with project and tutorial tags..."
    if ! aws s3api put-bucket-tagging \
        --bucket "$BUCKET_NAME" \
        --tagging 'TagSet=[{Key=project,Value=doc-smith},{Key=tutorial,Value=s3-gettingstarted}]' 2>&1; then
        echo "WARNING: Failed to tag bucket on creation"
    fi
) &
TAG_PID=$!

(
    echo "Enabling bucket versioning..."
    if ! aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled 2>&1; then
        echo "WARNING: Failed to enable versioning on creation"
    fi
) &
VERSION_PID=$!

(
    echo "Configuring SSE-S3 encryption..."
    if ! aws s3api put-bucket-encryption \
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
        }' 2>&1; then
        echo "WARNING: Failed to configure encryption on creation"
    fi
) &
ENCRYPT_PID=$!

(
    echo "Blocking all public access..."
    if ! aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration '{
            "BlockPublicAcls": true,
            "IgnorePublicAcls": true,
            "BlockPublicPolicy": true,
            "RestrictPublicBuckets": true
        }' 2>&1; then
        echo "WARNING: Failed to block public access on creation"
    fi
) &
PAB_PID=$!

# Wait for all background processes and capture any failures
WAIT_FAILED=0
wait $TAG_PID $VERSION_PID $ENCRYPT_PID $PAB_PID || WAIT_FAILED=1

if [ $WAIT_FAILED -ne 0 ]; then
    echo "WARNING: One or more background processes failed during bucket configuration"
fi

fi
echo ""

# ============================================================================
# Step 2: Upload a sample text file
# ============================================================================

echo "Step 2: Uploading a sample text file..."

SAMPLE_FILE="${TEMP_DIR}/sample.txt"
# Secure file creation with restricted permissions
umask 077
echo "Hello, Amazon S3! This is a sample file for the getting started tutorial." > "$SAMPLE_FILE"

if aws s3api put-object \
    --bucket "$BUCKET_NAME" \
    --key "sample.txt" \
    --body "$SAMPLE_FILE" \
    --server-side-encryption AES256 \
    --output text 2>&1 > /dev/null; then
    echo "File uploaded."
else
    echo "ERROR: Failed to upload sample file"
    handle_error "line $LINENO"
fi
echo ""

# ============================================================================
# Step 3: Download the object
# ============================================================================

echo "Step 3: Downloading the object..."

DOWNLOAD_FILE="${TEMP_DIR}/downloaded-sample.txt"
if aws s3api get-object \
    --bucket "$BUCKET_NAME" \
    --key "sample.txt" \
    "$DOWNLOAD_FILE" \
    --output text 2>&1 > /dev/null; then
    echo "Downloaded to: ${DOWNLOAD_FILE}"
    echo "Contents:"
    cat "$DOWNLOAD_FILE"
else
    echo "ERROR: Failed to download object"
    handle_error "line $LINENO"
fi
echo ""

# ============================================================================
# Step 4: Copy the object to a folder prefix
# ============================================================================

echo "Step 4: Copying object to a folder prefix..."

if aws s3api copy-object \
    --bucket "$BUCKET_NAME" \
    --copy-source "${BUCKET_NAME}/sample.txt" \
    --key "backup/sample.txt" \
    --server-side-encryption AES256 \
    --output text 2>&1 > /dev/null; then
    echo "Object copied to backup/sample.txt."
else
    echo "ERROR: Failed to copy object"
    handle_error "line $LINENO"
fi
echo ""

# ============================================================================
# Step 5: Upload a second version
# ============================================================================

echo "Step 5: Uploading a second version of sample.txt..."
umask 077
echo "Hello, Amazon S3! This is version 2 of the sample file." > "$SAMPLE_FILE"

if aws s3api put-object \
    --bucket "$BUCKET_NAME" \
    --key "sample.txt" \
    --body "$SAMPLE_FILE" \
    --server-side-encryption AES256 \
    --output text 2>&1 > /dev/null; then
    echo "Second version uploaded."
else
    echo "ERROR: Failed to upload second version"
    handle_error "line $LINENO"
fi
echo ""

# ============================================================================
# Step 6: List objects and versions
# ============================================================================

echo "Step 6: Listing objects..."

if aws s3api list-objects-v2 \
    --bucket "$BUCKET_NAME" \
    --output table 2>&1; then
    echo ""
else
    echo "WARNING: Failed to list objects"
fi

echo "Listing object versions..."

if aws s3api list-object-versions \
    --bucket "$BUCKET_NAME" \
    --output table 2>&1; then
    echo ""
else
    echo "WARNING: Failed to list object versions"
fi

# ============================================================================
# Step 7: Verify bucket configuration
# ============================================================================

echo "Step 7: Verifying bucket configuration..."

echo "Bucket tags:"
if aws s3api get-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --output table 2>&1; then
    echo ""
else
    echo "WARNING: Failed to retrieve bucket tags"
fi

echo "Bucket encryption:"
if aws s3api get-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --output table 2>&1; then
    echo ""
else
    echo "WARNING: Failed to retrieve bucket encryption"
fi

echo "Public access block:"
if aws s3api get-public-access-block \
    --bucket "$BUCKET_NAME" \
    --output table 2>&1; then
    echo ""
else
    echo "WARNING: Failed to retrieve public access block"
fi

# ============================================================================
# Step 8: Cleanup
# ============================================================================

echo ""
echo "============================================"
echo "TUTORIAL COMPLETE"
echo "============================================"
echo ""
echo "Resources created:"
if [ ${#CREATED_RESOURCES[@]} -eq 0 ]; then
    echo "  (none)"
else
    for RESOURCE in "${CREATED_RESOURCES[@]}"; do
        echo "  - ${RESOURCE}"
    done
fi
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
    echo "  aws s3 rm s3://${BUCKET_NAME} --recursive --quiet"
    echo ""
    if [ "$BUCKET_IS_SHARED" = "false" ]; then
        echo "  aws s3api delete-bucket --bucket ${BUCKET_NAME}"
    fi
    echo ""
    echo "  rm -rf ${TEMP_DIR}"
fi

echo ""
echo "Done."