#!/bin/bash
WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/sts-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}
[ -z "$REGION" ] && echo "ERROR: No region" && exit 1
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
ROLE_NAME="sts-tut-role-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name s3-read 2>/dev/null; aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Getting caller identity"
aws sts get-caller-identity --query '{Account:Account,Arn:Arn,UserId:UserId}' --output table
ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
CALLER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)
echo "Step 2: Creating a role to assume"
ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"$CALLER_ARN\"},\"Action\":\"sts:AssumeRole\"}]}" --query 'Role.Arn' --output text)
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name s3-read --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:ListAllMyBuckets"],"Resource":"*"}]}'
echo "  Role: $ROLE_ARN"
sleep 10
echo "Step 3: Assuming the role"
CREDS=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name tutorial-session --duration-seconds 900)
echo "$CREDS" | python3 -c "import sys,json;c=json.load(sys.stdin)['Credentials'];print(f\"  AccessKeyId: {c['AccessKeyId'][:8]}...\\n  Expiration: {c['Expiration']}\")"
echo "Step 4: Using temporary credentials"
AK=$(echo "$CREDS" | python3 -c "import sys,json;print(json.load(sys.stdin)['Credentials']['AccessKeyId'])")
SK=$(echo "$CREDS" | python3 -c "import sys,json;print(json.load(sys.stdin)['Credentials']['SecretAccessKey'])")
ST=$(echo "$CREDS" | python3 -c "import sys,json;print(json.load(sys.stdin)['Credentials']['SessionToken'])")
AWS_ACCESS_KEY_ID=$AK AWS_SECRET_ACCESS_KEY=$SK AWS_SESSION_TOKEN=$ST aws sts get-caller-identity --query '{Arn:Arn}' --output table
echo "Step 5: Session tags (decode token)"
aws sts decode-authorization-message --encoded-message test 2>/dev/null || echo "  (decode requires specific permissions — expected)"
echo ""
echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "
read -r CHOICE
[[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup || echo "Manual: aws iam delete-role --role-name $ROLE_NAME"
