#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing buckets with sizes"
aws s3api list-buckets --query 'Buckets[:10].{Name:Name,Created:CreationDate}' --output table
echo "Step 2: Getting bucket metrics (request count)"
B=$(aws s3api list-buckets --query 'Buckets[0].Name' --output text)
[ -n "$B" ] && [ "$B" != "None" ] && aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name NumberOfObjects --dimensions Name=BucketName,Value="$B" Name=StorageType,Value=AllStorageTypes --start-time "$(date -u -d '2 days ago' +%Y-%m-%dT%H:%M:%SZ)" --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --period 86400 --statistics Average --query 'Datapoints[0].Average' --output text 2>/dev/null || echo "  No metrics"
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
