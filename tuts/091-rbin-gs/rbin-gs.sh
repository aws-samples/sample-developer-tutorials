#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
        RESOURCE=(${CREATED_RESOURCES[$i]})
        type=${RESOURCE[0]}
        id=${RESOURCE[1]}
        case $type in
            rbin_rule) aws rbin delete-rule --identifier "$id" || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

REGION="${AWS_DEFAULT_REGION:-us-east-1}"
if [ -z "$REGION" ]; then
    echo "Region not configured. Please set the region using 'aws configure'."
    exit 1
fi

echo "=== Creating Recycle Bin rule ==="
RULE_ID=$(aws rbin create-rule --region "$REGION" --retention-period RetentionPeriodValue=1,RetentionPeriodUnit=DAYS --resource-type EBS_SNAPSHOT --query 'Identifier' --output text)
echo "Rule: $RULE_ID" 
CREATED_RESOURCES+=("rbin_rule:$RULE_ID")

aws rbin get-rule --region "$REGION" --identifier "$RULE_ID" --query 'Status' --output text 

echo "=== Updating rule to 7 days ==="
aws rbin update-rule --region "$REGION" --identifier "$RULE_ID" --retention-period RetentionPeriodValue=7,RetentionPeriodUnit=DAYS 

echo "=== Deleting rule ==="
aws rbin delete-rule --region "$REGION" --identifier "$RULE_ID" || true

echo "PASS"