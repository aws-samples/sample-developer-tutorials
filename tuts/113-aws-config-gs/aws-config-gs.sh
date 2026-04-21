#!/bin/bash
# Tutorial: Add a Config rule and check resource compliance
# Source: https://docs.aws.amazon.com/config/latest/developerguide/getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/config-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
RULE_NAME="tut-s3-encryption-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws configservice delete-config-rule --config-rule-name "$RULE_NAME" 2>/dev/null && echo "  Deleted rule $RULE_NAME"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Check Config recorder status
echo "Step 1: Checking Config recorder"
RECORDER=$(aws configservice describe-configuration-recorder-status \
    --query 'ConfigurationRecordersStatus[0].{Name:name,Recording:recording}' --output table 2>/dev/null)
if [ -z "$RECORDER" ]; then
    echo "  No Config recorder found. Enable AWS Config in the console first."
    echo "  https://console.aws.amazon.com/config/home"
    rm -rf "$WORK_DIR"
    exit 1
fi
echo "$RECORDER"

# Step 2: List discovered resources
echo "Step 2: Listing discovered S3 buckets"
aws configservice list-discovered-resources --resource-type AWS::S3::Bucket \
    --query 'resourceIdentifiers[:5].{Type:resourceType,Id:resourceId}' --output table

# Step 3: Add a managed rule
echo "Step 3: Adding managed rule: $RULE_NAME"
aws configservice put-config-rule --config-rule "{
    \"ConfigRuleName\":\"$RULE_NAME\",
    \"Source\":{\"Owner\":\"AWS\",\"SourceIdentifier\":\"S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED\"},
    \"Scope\":{\"ComplianceResourceTypes\":[\"AWS::S3::Bucket\"]}
}"
echo "  Rule checks: S3 bucket server-side encryption"

# Step 4: Trigger evaluation
echo "Step 4: Triggering rule evaluation"
aws configservice start-config-rules-evaluation --config-rule-names "$RULE_NAME" 2>/dev/null || true
echo "  Evaluation started (takes 30-60 seconds)"
sleep 30

# Step 5: Check compliance
echo "Step 5: Compliance results"
aws configservice get-compliance-details-by-config-rule --config-rule-name "$RULE_NAME" \
    --query 'EvaluationResults[:5].{Resource:EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId,Compliance:ComplianceType}' --output table 2>/dev/null || \
    echo "  No results yet — evaluation may still be running"

# Step 6: Compliance summary
echo "Step 6: Compliance summary"
aws configservice describe-compliance-by-config-rule --config-rule-names "$RULE_NAME" \
    --query 'ComplianceByConfigRules[0].{Rule:ConfigRuleName,Compliance:Compliance.ComplianceType}' --output table

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws configservice delete-config-rule --config-rule-name $RULE_NAME"
fi
