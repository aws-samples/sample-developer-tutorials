#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/health-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}
[ -z "$REGION" ] && echo "ERROR: No region" && exit 1
export AWS_DEFAULT_REGION=us-east-1
echo "Region: us-east-1 (Health API is global)"
echo "Step 1: Describing events (last 7 days)"
aws health describe-events --filter '{"startTimes":[{"from":"'$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)'"}]}' --query 'events[:5].{Service:service,Type:eventTypeCode,Status:statusCode,Region:region}' --output table 2>/dev/null || echo "  No recent events (or Health API requires Business/Enterprise support)"
echo "Step 2: Describing event types"
aws health describe-event-types --filter '{"services":["EC2"]}' --query 'eventTypes[:5].{Code:code,Service:service,Category:category}' --output table 2>/dev/null || echo "  Cannot describe event types"
echo "Step 3: Describing affected entities"
aws health describe-affected-entities --filter '{"eventArns":["arn:aws:health:us-east-1::event/EC2/example"]}' 2>/dev/null || echo "  No affected entities (expected with no active events)"
echo ""
echo "Tutorial complete. No resources were created — Health API is read-only."
echo "Note: Full Health API access requires Business or Enterprise Support plan."
rm -rf "$WORK_DIR"
