#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/s3v.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text); echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); BUCKET="s3ver-tut-${RANDOM_ID}-${ACCOUNT}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws s3api list-object-versions --bucket "$BUCKET" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}, Quiet: `true`}' > "$WORK_DIR/del.json" 2>/dev/null && aws s3api delete-objects --bucket "$BUCKET" --delete "file://$WORK_DIR/del.json" > /dev/null 2>&1; aws s3api list-object-versions --bucket "$BUCKET" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}, Quiet: `true`}' > "$WORK_DIR/del2.json" 2>/dev/null && aws s3api delete-objects --bucket "$BUCKET" --delete "file://$WORK_DIR/del2.json" > /dev/null 2>&1; aws s3 rb "s3://$BUCKET" 2>/dev/null && echo "  Deleted bucket"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating versioned bucket"
if [ "$REGION" = "us-east-1" ]; then aws s3api create-bucket --bucket "$BUCKET" > /dev/null; else aws s3api create-bucket --bucket "$BUCKET" --create-bucket-configuration LocationConstraint="$REGION" > /dev/null; fi
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
echo "Step 2: Uploading multiple versions"
echo "version 1" > "$WORK_DIR/file.txt"; aws s3 cp "$WORK_DIR/file.txt" "s3://$BUCKET/file.txt" --quiet
echo "version 2" > "$WORK_DIR/file.txt"; aws s3 cp "$WORK_DIR/file.txt" "s3://$BUCKET/file.txt" --quiet
echo "version 3" > "$WORK_DIR/file.txt"; aws s3 cp "$WORK_DIR/file.txt" "s3://$BUCKET/file.txt" --quiet
echo "  Uploaded 3 versions"
echo "Step 3: Listing versions"
aws s3api list-object-versions --bucket "$BUCKET" --prefix file.txt --query 'Versions[].{Key:Key,VersionId:VersionId,IsLatest:IsLatest,Size:Size}' --output table
echo "Step 4: Getting a specific version"
OLDEST=$(aws s3api list-object-versions --bucket "$BUCKET" --prefix file.txt --query 'Versions[-1].VersionId' --output text)
aws s3api get-object --bucket "$BUCKET" --key file.txt --version-id "$OLDEST" "$WORK_DIR/old.txt" > /dev/null
echo "  Oldest version content: $(cat "$WORK_DIR/old.txt")"
echo "Step 5: Deleting (creates delete marker)"
aws s3api delete-object --bucket "$BUCKET" --key file.txt > /dev/null
echo "  Delete marker created"
aws s3api list-object-versions --bucket "$BUCKET" --prefix file.txt --query 'DeleteMarkers[].{Key:Key,IsLatest:IsLatest}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
