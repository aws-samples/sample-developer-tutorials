#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing tables"; aws dynamodb list-tables --query 'TableNames' --output table
echo "Step 2: Table details"
T=$(aws dynamodb list-tables --query 'TableNames[0]' --output text 2>/dev/null)
[ -n "$T" ] && [ "$T" != "None" ] && aws dynamodb describe-table --table-name "$T" --query 'Table.{Name:TableName,Status:TableStatus,Items:ItemCount,Size:TableSizeBytes,Billing:BillingModeSummary.BillingMode}' --output table || echo "  No tables"
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
