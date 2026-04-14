#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing existing rules"
aws cloudwatch describe-insight-rules --query 'InsightRules[:5].{Name:Name,State:State}' --output table 2>/dev/null || echo "  No insight rules"
echo "Step 2: Listing log groups for analysis"
aws logs describe-log-groups --limit 5 --query 'logGroups[].{Name:logGroupName,Stored:storedBytes}' --output table
echo "Step 3: Getting metric widget image (base64)"
aws cloudwatch get-metric-widget-image --metric-widget '{"metrics":[["AWS/EC2","CPUUtilization"]],"period":300,"stat":"Average","region":"us-east-1","title":"EC2 CPU"}' --query 'MetricWidgetImage' --output text | head -c 50
echo "..."
echo ""; echo "Tutorial complete. No resources created — read-only."
rm -rf "$WORK_DIR"
