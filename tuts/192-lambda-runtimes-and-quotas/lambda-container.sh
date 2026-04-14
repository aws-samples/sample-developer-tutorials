#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing Lambda runtimes"
aws lambda list-layers --compatible-runtime python3.12 --query 'Layers[:5].{Name:LayerName,Version:LatestMatchingVersion.Version}' --output table 2>/dev/null || echo "  No compatible layers"
echo "Step 2: Getting Lambda service quotas"
aws lambda get-account-settings --query 'AccountLimit.{CodeSize:TotalCodeSize,ConcurrentExec:ConcurrentExecutions,FunctionCount:FunctionCount}' --output table
echo "Step 3: Listing functions by runtime"
aws lambda list-functions --query 'Functions[?Runtime==`python3.12`][:5].{Name:FunctionName,Runtime:Runtime,Size:CodeSize}' --output table 2>/dev/null || echo "  No Python 3.12 functions"
echo "Step 4: Listing event source mappings"
aws lambda list-event-source-mappings --query 'EventSourceMappings[:5].{Function:FunctionArn,Source:EventSourceArn,State:State}' --output table 2>/dev/null || echo "  No event source mappings"
echo ""; echo "Tutorial complete. No resources created — read-only."
rm -rf "$WORK_DIR"
