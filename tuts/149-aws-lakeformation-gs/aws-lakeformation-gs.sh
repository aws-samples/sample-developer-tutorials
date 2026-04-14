#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/lf.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Getting data lake settings"
aws lakeformation get-data-lake-settings --query 'DataLakeSettings.{Admins:DataLakeAdmins|length(@),CreateDBDefault:CreateDatabaseDefaultPermissions|length(@)}' --output table
echo "Step 2: Listing resources"
aws lakeformation list-resources --query 'ResourceInfoList[:5].{Arn:ResourceArn}' --output table 2>/dev/null || echo "  No registered resources"
echo "Step 3: Listing permissions"
aws lakeformation list-permissions --query 'PrincipalResourcePermissions[:5].{Principal:Principal.DataLakePrincipalIdentifier,Resource:Resource}' --output json 2>/dev/null | python3 -c "import sys,json;d=json.load(sys.stdin);print(f'  {len(d)} permissions found')" 2>/dev/null || echo "  No permissions"
echo ""; echo "Tutorial complete. No resources created — Lake Formation is read-only in this tutorial."
rm -rf "$WORK_DIR"
