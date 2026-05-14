#!/bin/bash
set -e
echo "Creating Recycle Bin rule..."
RULE_ID=$(aws rbin create-rule --retention-period RetentionPeriodValue=1,RetentionPeriodUnit=DAYS --resource-type EBS_SNAPSHOT --query 'Identifier' --output text)
echo "Rule: $RULE_ID"
aws rbin get-rule --identifier "$RULE_ID" --query 'Status' --output text
echo "Updating rule to 7 days..."
aws rbin update-rule --identifier "$RULE_ID" --retention-period RetentionPeriodValue=7,RetentionPeriodUnit=DAYS
echo "Deleting rule..."
aws rbin delete-rule --identifier "$RULE_ID" || true
echo "PASS"