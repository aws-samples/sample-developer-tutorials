#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing Lambda log groups"; aws logs describe-log-groups --log-group-name-prefix /aws/lambda --query 'logGroups[:10].{Name:logGroupName,Stored:storedBytes,Retention:retentionInDays}' --output table
echo "Step 2: Getting recent log events from a function"
LG=$(aws logs describe-log-groups --log-group-name-prefix /aws/lambda --query 'logGroups[0].logGroupName' --output text 2>/dev/null)
[ -n "$LG" ] && [ "$LG" != "None" ] && { LS=$(aws logs describe-log-streams --log-group-name "$LG" --order-by LastEventTime --descending --limit 1 --query 'logStreams[0].logStreamName' --output text); aws logs get-log-events --log-group-name "$LG" --log-stream-name "$LS" --limit 5 --query 'events[].message' --output text; } || echo "  No Lambda log groups"
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
