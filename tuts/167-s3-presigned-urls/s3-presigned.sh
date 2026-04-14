#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/presign.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text); echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); BUCKET="presign-tut-${RANDOM_ID}-${ACCOUNT}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws s3 rm "s3://$BUCKET" --recursive --quiet 2>/dev/null; aws s3 rb "s3://$BUCKET" 2>/dev/null && echo "  Deleted bucket"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating bucket"
if [ "$REGION" = "us-east-1" ]; then aws s3api create-bucket --bucket "$BUCKET" > /dev/null; else aws s3api create-bucket --bucket "$BUCKET" --create-bucket-configuration LocationConstraint="$REGION" > /dev/null; fi
echo "Step 2: Uploading a file"
echo "Hello from presigned URL tutorial" > "$WORK_DIR/data.txt"
aws s3 cp "$WORK_DIR/data.txt" "s3://$BUCKET/data.txt" --quiet
echo "Step 3: Generating presigned download URL (expires in 5 min)"
DOWNLOAD_URL=$(aws s3 presign "s3://$BUCKET/data.txt" --expires-in 300)
echo "  URL: ${DOWNLOAD_URL:0:80}..."
echo "Step 4: Testing presigned download"
curl -s "$DOWNLOAD_URL"
echo ""
echo "Step 5: Generating presigned upload URL"
UPLOAD_URL=$(aws s3 presign "s3://$BUCKET/uploaded.txt" --expires-in 300)
echo "  Upload URL generated (expires in 5 min)"
echo "Step 6: Listing objects"
aws s3api list-objects-v2 --bucket "$BUCKET" --query 'Contents[].{Key:Key,Size:Size}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
