#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/waf-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}
[ -z "$REGION" ] && echo "ERROR: No region" && exit 1
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4)
ACL_NAME="tut-acl-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; if [ -n "$ACL_ID" ]; then LOCK=$(aws wafv2 get-web-acl --name "$ACL_NAME" --scope REGIONAL --id "$ACL_ID" --query 'LockToken' --output text 2>/dev/null); aws wafv2 delete-web-acl --name "$ACL_NAME" --scope REGIONAL --id "$ACL_ID" --lock-token "$LOCK" 2>/dev/null && echo "  Deleted web ACL"; fi; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating web ACL: $ACL_NAME"
ACL_ID=$(aws wafv2 create-web-acl --name "$ACL_NAME" --scope REGIONAL \
    --default-action '{"Allow":{}}' \
    --visibility-config '{"SampledRequestsEnabled":true,"CloudWatchMetricsEnabled":true,"MetricName":"tutorialACL"}' \
    --rules '[{"Name":"RateLimit","Priority":1,"Statement":{"RateBasedStatement":{"Limit":1000,"AggregateKeyType":"IP"}},"Action":{"Block":{}},"VisibilityConfig":{"SampledRequestsEnabled":true,"CloudWatchMetricsEnabled":true,"MetricName":"RateLimit"}}]' \
    --query 'Summary.Id' --output text)
echo "  ACL ID: $ACL_ID"
echo "Step 2: Describing web ACL"
aws wafv2 get-web-acl --name "$ACL_NAME" --scope REGIONAL --id "$ACL_ID" --query 'WebACL.{Name:Name,Id:Id,Rules:Rules|length(@),DefaultAction:DefaultAction}' --output table
echo "Step 3: Listing available managed rule groups"
aws wafv2 list-available-managed-rule-groups --scope REGIONAL --query 'ManagedRuleGroups[:5].{Vendor:VendorName,Name:Name}' --output table
echo "Step 4: Listing web ACLs"
aws wafv2 list-web-acls --scope REGIONAL --query 'WebACLs[?starts_with(Name, `tut-`)].{Name:Name,Id:Id}' --output table
echo ""
echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "
read -r CHOICE
[[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup || echo "Manual: aws wafv2 delete-web-acl (requires lock-token)"
