#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing functions"; aws lambda list-functions --query 'Functions[:10].{Name:FunctionName,Runtime:Runtime,Size:CodeSize,Modified:LastModified}' --output table
echo "Step 2: Function count by runtime"; aws lambda list-functions --query 'Functions[].Runtime' --output text | tr '\t' '\n' | sort | uniq -c | sort -rn
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
