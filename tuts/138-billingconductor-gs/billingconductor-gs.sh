#!/bin/bash
set -e

SUFFIX=$(date +%s | sha256sum | base64 | head -c 8)
CLIENT_TOKEN=$(date +%s | sha256sum | base64 | head -c 8)

PRICING_RULE_NAME="TestPricingRule${SUFFIX}"
PRICING_RULE_DESCRIPTION="Test Pricing Rule Description"
PRICING_RULE_SCOPE="GLOBAL"
PRICING_RULE_TYPE="MARKUP"
MODIFIER_PERCENTAGE=10.0

PRICING_RULE_ARN=$(aws billingconductor create-pricing-rule \
    --name "${PRICING_RULE_NAME}" \
    --description "${PRICING_RULE_DESCRIPTION}" \
    --scope "${PRICING_RULE_SCOPE}" \
    --type "${PRICING_RULE_TYPE}" \
    --modifier-percentage ${MODIFIER_PERCENTAGE} \
    --client-token "${CLIENT_TOKEN}" \
    --query 'Arn' --output text)

echo "Pricing Rule created: ${PRICING_RULE_ARN}"

VERIFY_RULE=$(aws billingconductor list-pricing-rules \
    --filters "Arns=[${PRICING_RULE_ARN}]" \
    --query 'PricingRules[0].Name' --output text)

if [ "${VERIFY_RULE}" == "${PRICING_RULE_NAME}" ]; then
    echo "Pricing Rule verified: ${PRICING_RULE_NAME}"
else
    echo "Pricing Rule verification failed"
    exit 1
fi

echo "Listing Pricing Rules:"
aws billingconductor list-pricing-rules || true

aws billingconductor delete-pricing-rule \
    --arn "${PRICING_RULE_ARN}" || true

echo "Pricing Rule deleted: ${PRICING_RULE_ARN}"
echo "PASS"