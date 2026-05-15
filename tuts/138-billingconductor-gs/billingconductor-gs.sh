#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()
CLIENT_TOKEN=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

cleanup_resources() {
    for ARN in "${CREATED_RESOURCES[@]}"; do
        aws billingconductor delete-pricing-rule --arn "${ARN}" || true
    done
    rm -rf "${TEMP_DIR}"
}

trap cleanup_resources EXIT

# Create Pricing Rule
echo "Creating Pricing Rule..." >> "${LOG_FILE}"
PRICING_RULE_NAME="TestPricingRule${SUFFIX}"
PRICING_RULE_DESCRIPTION="Test Pricing Rule Description"
PRICING_RULE_SCOPE="GLOBAL"
PRICING_RULE_TYPE="MARKUP"
MODIFIER_PERCENTAGE=10.0

PRICING_RULE_ARN=$(aws billingconductor create-pricing-rule \
    --tags '{"project": "doc-smith", "tutorial": "billingconductor-gs"}' \
    --name "${PRICING_RULE_NAME}" \
    --description "${PRICING_RULE_DESCRIPTION}" \
    --scope "${PRICING_RULE_SCOPE}" \
    --type "${PRICING_RULE_TYPE}" \
    --modifier-percentage ${MODIFIER_PERCENTAGE} \
    --client-token "${CLIENT_TOKEN}" \
    --query 'Arn' --output text)

echo "Pricing Rule created: ${PRICING_RULE_ARN}" >> "${LOG_FILE}"
CREATED_RESOURCES+=("${PRICING_RULE_ARN}")

# Verify Pricing Rule
echo "Verifying Pricing Rule..." >> "${LOG_FILE}"
VERIFY_RULE=$(aws billingconductor list-pricing-rules \
    --filters "Arns=[${PRICING_RULE_ARN}]" \
    --query 'PricingRules[0].Name' --output text)

if [ "${VERIFY_RULE}" == "${PRICING_RULE_NAME}" ]; then
    echo "Pricing Rule verified: ${PRICING_RULE_NAME}" >> "${LOG_FILE}"
else
    echo "Pricing Rule verification failed" >> "${LOG_FILE}"
    exit 1
fi

# List Pricing Rules
echo "Listing Pricing Rules..." >> "${LOG_FILE}"
aws billingconductor list-pricing-rules || true

echo "Pricing Rule deleted: ${PRICING_RULE_ARN}" >> "${LOG_FILE}"
echo "PASS" >> "${LOG_FILE}"
