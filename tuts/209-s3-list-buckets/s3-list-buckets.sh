#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing all buckets"; aws s3api list-buckets --query 'Buckets[].{Name:Name,Created:CreationDate}' --output table
echo "Step 2: Bucket count"; echo "  Total: $(aws s3api list-buckets --query 'Buckets | length(@)' --output text) buckets"
echo "Step 3: Checking public access block"; B=$(aws s3api list-buckets --query 'Buckets[0].Name' --output text); [ -n "$B" ] && [ "$B" != "None" ] && aws s3api get-public-access-block --bucket "$B" --query 'PublicAccessBlockConfiguration' --output table 2>/dev/null || echo "  No public access block"
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
