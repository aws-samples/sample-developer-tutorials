#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing objects with storage classes"
BUCKET=$(aws s3api list-buckets --query 'Buckets[0].Name' --output text)
[ -n "$BUCKET" ] && [ "$BUCKET" != "None" ] && aws s3api list-objects-v2 --bucket "$BUCKET" --max-keys 10 --query 'Contents[].{Key:Key,Size:Size,Class:StorageClass}' --output table || echo "  No buckets"
echo "Step 2: Storage class reference"
echo "  STANDARD: Default, frequently accessed"
echo "  STANDARD_IA: Infrequent access, lower cost"
echo "  ONEZONE_IA: Single AZ, lowest IA cost"
echo "  INTELLIGENT_TIERING: Auto-tiering"
echo "  GLACIER_IR: Instant retrieval archive"
echo "  GLACIER: Flexible retrieval (minutes to hours)"
echo "  DEEP_ARCHIVE: Lowest cost (12-48 hours)"
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
