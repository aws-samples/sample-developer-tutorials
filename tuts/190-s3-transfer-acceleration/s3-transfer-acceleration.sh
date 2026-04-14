#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
B="accel-tut-${RANDOM_ID}-${ACCOUNT}"
cleanup() { echo "Cleaning up..."; aws s3 rm "s3://$B" --recursive --quiet 2>/dev/null; aws s3 rb "s3://$B" 2>/dev/null && echo "  Deleted bucket"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating bucket"
aws s3api create-bucket --bucket "$B" > /dev/null
echo "Step 2: Enabling Transfer Acceleration"
aws s3api put-bucket-accelerate-configuration --bucket "$B" --accelerate-configuration Status=Enabled
echo "  Acceleration enabled"
echo "Step 3: Getting acceleration status"
aws s3api get-bucket-accelerate-configuration --bucket "$B" --query '{Status:Status}' --output table
echo "Step 4: Accelerated endpoint"
echo "  https://${B}.s3-accelerate.amazonaws.com"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && cleanup
