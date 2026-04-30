#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
SRC="inv-src-${RANDOM_ID}-${ACCOUNT}"; DST="inv-dst-${RANDOM_ID}-${ACCOUNT}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap '"'"'handle_error $LINENO'"'"' ERR
cleanup() { echo "Cleaning up..."; aws s3api delete-bucket-inventory-configuration --bucket "$SRC" --id tutorial-inventory 2>/dev/null; aws s3 rm "s3://$SRC" --recursive --quiet 2>/dev/null; aws s3 rb "s3://$SRC" 2>/dev/null; aws s3 rm "s3://$DST" --recursive --quiet 2>/dev/null; aws s3 rb "s3://$DST" 2>/dev/null; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating source and destination buckets"
aws s3api create-bucket --bucket "$SRC" > /dev/null; aws s3api create-bucket --bucket "$DST" > /dev/null
echo "Step 2: Configuring inventory"
aws s3api put-bucket-inventory-configuration --bucket "$SRC" --id tutorial-inventory --inventory-configuration "{\"Destination\":{\"S3BucketDestination\":{\"Bucket\":\"arn:aws:s3:::$DST\",\"Format\":\"CSV\"}},\"IsEnabled\":true,\"Id\":\"tutorial-inventory\",\"IncludedObjectVersions\":\"Current\",\"Schedule\":{\"Frequency\":\"Weekly\"},\"OptionalFields\":[\"Size\",\"LastModifiedDate\",\"StorageClass\"]}"
echo "  Inventory configured (weekly, CSV)"
echo "Step 3: Getting inventory configuration"
aws s3api get-bucket-inventory-configuration --bucket "$SRC" --id tutorial-inventory --query "InventoryConfiguration.{Id:Id,Enabled:IsEnabled,Frequency:Schedule.Frequency}" --output table
echo "  Note: First inventory report generates within 48 hours"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && cleanup
