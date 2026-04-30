#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/ap.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; ACCOUNT=$(aws sts get-caller-identity --query Account --output text); echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); BUCKET="ap-tut-${RANDOM_ID}-${ACCOUNT}"; AP_NAME="tut-ap-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws s3control delete-access-point --account-id "$ACCOUNT" --name "$AP_NAME" 2>/dev/null && echo "  Deleted access point"; aws s3 rm "s3://$BUCKET" --recursive --quiet 2>/dev/null; aws s3 rb "s3://$BUCKET" 2>/dev/null && echo "  Deleted bucket"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating bucket"
if [ "$REGION" = "us-east-1" ]; then aws s3api create-bucket --bucket "$BUCKET" > /dev/null; else aws s3api create-bucket --bucket "$BUCKET" --create-bucket-configuration LocationConstraint="$REGION" > /dev/null; fi
echo "Step 2: Creating access point: $AP_NAME"
aws s3control create-access-point --account-id "$ACCOUNT" --name "$AP_NAME" --bucket "$BUCKET" > /dev/null
echo "  Access point created"
echo "Step 3: Getting access point details"
aws s3control get-access-point --account-id "$ACCOUNT" --name "$AP_NAME" --query '{Name:Name,Bucket:Bucket,NetworkOrigin:NetworkOrigin}' --output table
echo "Step 4: Listing access points"
aws s3control list-access-points --account-id "$ACCOUNT" --bucket "$BUCKET" --query 'AccessPointList[].{Name:Name,Bucket:Bucket}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
