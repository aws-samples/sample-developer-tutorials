#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
B="lock-tut-${RANDOM_ID}-${ACCOUNT}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo "Cleaning up..."; echo "  Object Lock buckets require all versions to expire before deletion."; echo "  Manual: aws s3api delete-bucket --bucket $B (after retention expires)"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating bucket with Object Lock"
aws s3api create-bucket --bucket "$B" --object-lock-enabled-for-bucket > /dev/null
aws s3api put-bucket-versioning --bucket "$B" --versioning-configuration Status=Enabled
echo "Step 2: Setting default retention (1 day governance mode)"
aws s3api put-object-lock-configuration --bucket "$B" --object-lock-configuration '{"ObjectLockEnabled":"Enabled","Rule":{"DefaultRetention":{"Mode":"GOVERNANCE","Days":1}}}'
echo "Step 3: Getting lock configuration"
aws s3api get-object-lock-configuration --bucket "$B" --query "ObjectLockConfiguration.Rule.DefaultRetention.{Mode:Mode,Days:Days}" --output table
echo "Step 4: Uploading a locked object"
echo "protected data" > "$WORK_DIR/data.txt"
aws s3 cp "$WORK_DIR/data.txt" "s3://$B/data.txt" --quiet
echo "  Object uploaded with governance-mode retention"
echo "Step 5: Verifying lock"
aws s3api head-object --bucket "$B" --key data.txt --query "{Lock:ObjectLockMode,Retain:ObjectLockRetainUntilDate}" --output table
echo ""; echo "Tutorial complete."
echo "Note: Object Lock prevents deletion until retention expires."
echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && cleanup
