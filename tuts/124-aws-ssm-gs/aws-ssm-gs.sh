#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/ssm-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}
[ -z "$REGION" ] && echo "ERROR: No region" && exit 1
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws ssm delete-parameter --name "/tutorial/$RANDOM_ID/db-host" 2>/dev/null; aws ssm delete-parameter --name "/tutorial/$RANDOM_ID/db-password" 2>/dev/null; aws ssm delete-parameter --name "/tutorial/$RANDOM_ID/app-config" 2>/dev/null; echo "  Deleted parameters"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating a String parameter"
aws ssm put-parameter --name "/tutorial/$RANDOM_ID/db-host" --value "db.example.com" --type String --query 'Version' --output text > /dev/null
echo "  Created /tutorial/$RANDOM_ID/db-host"
echo "Step 2: Creating a SecureString parameter"
aws ssm put-parameter --name "/tutorial/$RANDOM_ID/db-password" --value "s3cret-pass-123" --type SecureString --query 'Version' --output text > /dev/null
echo "  Created /tutorial/$RANDOM_ID/db-password (encrypted)"
echo "Step 3: Creating a StringList parameter"
aws ssm put-parameter --name "/tutorial/$RANDOM_ID/app-config" --value "debug=false,timeout=30,retries=3" --type StringList --query 'Version' --output text > /dev/null
echo "  Created /tutorial/$RANDOM_ID/app-config"
echo "Step 4: Getting parameters"
aws ssm get-parameter --name "/tutorial/$RANDOM_ID/db-host" --query 'Parameter.{Name:Name,Value:Value,Type:Type}' --output table
aws ssm get-parameter --name "/tutorial/$RANDOM_ID/db-password" --with-decryption --query 'Parameter.{Name:Name,Value:Value,Type:Type}' --output table
echo "Step 5: Getting parameters by path"
aws ssm get-parameters-by-path --path "/tutorial/$RANDOM_ID" --with-decryption --query 'Parameters[].{Name:Name,Type:Type,Value:Value}' --output table
echo "Step 6: Parameter history"
aws ssm put-parameter --name "/tutorial/$RANDOM_ID/db-host" --value "db-v2.example.com" --type String --overwrite --query 'Version' --output text > /dev/null
aws ssm get-parameter-history --name "/tutorial/$RANDOM_ID/db-host" --query 'Parameters[].{Version:Version,Value:Value}' --output table
echo ""
echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "
read -r CHOICE
[[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup || echo "Manual: aws ssm delete-parameters --names /tutorial/$RANDOM_ID/db-host /tutorial/$RANDOM_ID/db-password /tutorial/$RANDOM_ID/app-config"
