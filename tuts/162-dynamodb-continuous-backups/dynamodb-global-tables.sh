#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/ddb-global.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); TABLE="tut-global-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws dynamodb delete-table --table-name "$TABLE" > /dev/null 2>&1 && echo "  Deleted table"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating table"
aws dynamodb create-table --table-name "$TABLE" --key-schema AttributeName=pk,KeyType=HASH --attribute-definitions AttributeName=pk,AttributeType=S --billing-mode PAY_PER_REQUEST --query 'TableDescription.TableName' --output text > /dev/null
aws dynamodb wait table-exists --table-name "$TABLE"
echo "Step 2: Enabling point-in-time recovery"
aws dynamodb update-continuous-backups --table-name "$TABLE" --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true > /dev/null
echo "  PITR enabled"
echo "Step 3: Describing continuous backups"
aws dynamodb describe-continuous-backups --table-name "$TABLE" --query 'ContinuousBackupsDescription.{Status:ContinuousBackupsStatus,PITR:PointInTimeRecoveryDescription.PointInTimeRecoveryStatus}' --output table
echo "Step 4: Writing and reading items"
aws dynamodb put-item --table-name "$TABLE" --item '{"pk":{"S":"item-1"},"data":{"S":"Hello"}}' 2>/dev/null
aws dynamodb get-item --table-name "$TABLE" --key '{"pk":{"S":"item-1"}}' --query 'Item.{pk:pk.S,data:data.S}' --output table
echo "Step 5: Table details"
aws dynamodb describe-table --table-name "$TABLE" --query 'Table.{Name:TableName,Status:TableStatus,Items:ItemCount,Billing:BillingModeSummary.BillingMode}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
