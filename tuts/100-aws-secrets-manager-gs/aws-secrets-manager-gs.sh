#!/bin/bash
# Tutorial: Store and retrieve secrets with AWS Secrets Manager
# Source: https://docs.aws.amazon.com/secretsmanager/latest/userguide/getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/secretsmanager-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
SECRET_NAME="tutorial/db-creds-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws secretsmanager delete-secret --secret-id "$SECRET_NAME" \
        --force-delete-without-recovery > /dev/null 2>&1 && \
        echo "  Deleted secret $SECRET_NAME (immediate, no recovery)"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a secret
echo "Step 1: Creating secret: $SECRET_NAME"
SECRET_ARN=$(aws secretsmanager create-secret --name "$SECRET_NAME" \
    --description "Tutorial database credentials" \
    --secret-string '{"username":"admin","password":"tutorial-pass-12345","engine":"mysql","host":"db.example.com","port":3306}' \
    --query 'ARN' --output text)
echo "  Secret ARN: $SECRET_ARN"

# Step 2: Retrieve the secret
echo "Step 2: Retrieving the secret"
aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" \
    --query '{Name:Name,Value:SecretString}' --output table

# Step 3: Update the secret
echo "Step 3: Updating the secret value"
aws secretsmanager put-secret-value --secret-id "$SECRET_NAME" \
    --secret-string '{"username":"admin","password":"new-secure-pass-67890","engine":"mysql","host":"db.example.com","port":3306}' > /dev/null
echo "  Secret updated"

# Step 4: Retrieve the updated secret
echo "Step 4: Retrieving updated secret"
aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" \
    --query 'SecretString' --output text | python3 -m json.tool

# Step 5: Describe the secret
echo "Step 5: Describing the secret"
aws secretsmanager describe-secret --secret-id "$SECRET_NAME" \
    --query '{Name:Name,Description:Description,Created:CreatedDate,LastChanged:LastChangedDate,Versions:VersionIdsToStages|length(@)}' --output table

# Step 6: Tag the secret
echo "Step 6: Adding tags"
aws secretsmanager tag-resource --secret-id "$SECRET_NAME" \
    --tags Key=Environment,Value=tutorial Key=Application,Value=database
aws secretsmanager describe-secret --secret-id "$SECRET_NAME" \
    --query 'Tags[].{Key:Key,Value:Value}' --output table

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws secretsmanager delete-secret --secret-id $SECRET_NAME --force-delete-without-recovery"
fi
