#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/mc.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Getting MediaConvert endpoint"
ENDPOINT=$(aws mediaconvert describe-endpoints --query 'Endpoints[0].Url' --output text)
echo "  Endpoint: $ENDPOINT"
echo "Step 2: Listing job templates"
aws mediaconvert list-job-templates --endpoint-url "$ENDPOINT" --query 'JobTemplates[:5].{Name:Name,Type:Type}' --output table 2>/dev/null || echo "  No custom templates"
echo "Step 3: Listing presets"
aws mediaconvert list-presets --endpoint-url "$ENDPOINT" --list-by SYSTEM --query 'Presets[:5].{Name:Name,Category:Category}' --output table 2>/dev/null || echo "  No presets"
echo "Step 4: Listing queues"
aws mediaconvert list-queues --endpoint-url "$ENDPOINT" --query 'Queues[].{Name:Name,Status:Status,Type:Type}' --output table
echo ""; echo "Tutorial complete. No resources created — MediaConvert is job-based."
rm -rf "$WORK_DIR"
