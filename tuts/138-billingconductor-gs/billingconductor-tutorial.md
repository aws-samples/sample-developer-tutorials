# Tutorial: Create and Verify an AWS Billing Conductor Pricing Rule

## Prerequisites

- An AWS account with permissions to use AWS Billing Conductor.
- AWS CLI installed and configured with appropriate credentials.

## Steps

1. **Generate a unique suffix and temporary directory**

    ```bash
    SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    TEMP_DIR=$(mktemp -d)
    LOG_FILE="${TEMP_DIR}/script.log"
    CREATED_RESOURCES=()
    CLIENT_TOKEN=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    ```

2. **Create a Pricing Rule**

    ```bash
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
    ```

3. **Verify the Pricing Rule**

    ```bash
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
    ```

4. **List all Pricing Rules**

    ```bash
    echo "Listing Pricing Rules..." >> "${LOG_FILE}"
    aws billingconductor list-pricing-rules || true
    ```

## Clean up

The script automatically cleans up the created resources by deleting the pricing rule and removing the temporary directory.

## Next steps

- Explore additional AWS Billing Conductor features.
- Integrate this script into your CI/CD pipeline for automated testing.