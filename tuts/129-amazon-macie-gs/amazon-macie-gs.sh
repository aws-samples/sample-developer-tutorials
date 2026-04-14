#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/macie-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}
[ -z "$REGION" ] && echo "ERROR: No region" && exit 1
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"
PREEXISTING=false
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ "$PREEXISTING" != true ] && aws macie2 disable-macie 2>/dev/null && echo "  Disabled Macie" || echo "  Macie was pre-existing — not disabling"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Enabling Macie"
STATUS=$(aws macie2 get-macie-session --query 'status' --output text 2>/dev/null || echo "DISABLED")
if [ "$STATUS" = "ENABLED" ]; then echo "  Already enabled"; PREEXISTING=true; else aws macie2 enable-macie 2>/dev/null; echo "  Macie enabled"; fi
echo "Step 2: Getting session details"
aws macie2 get-macie-session --query '{Status:status,Created:createdAt,Updated:updatedAt}' --output table
echo "Step 3: Listing S3 buckets"
aws macie2 describe-buckets --query 'buckets[:5].{Name:bucketName,Encryption:serverSideEncryption.type,Public:publicAccess.effectivePermission}' --output table 2>/dev/null || echo "  Bucket inventory not ready yet"
echo "Step 4: Getting usage statistics"
aws macie2 get-usage-totals --query 'usageTotals[].{Type:type,Amount:estimatedCost}' --output table 2>/dev/null || echo "  No usage data yet"
echo ""
echo "Tutorial complete."
[ "$PREEXISTING" = true ] && echo "Macie was already enabled — not disabling." || { echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup; }
