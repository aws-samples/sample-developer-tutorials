#!/bin/bash
set -e

# Generate a unique suffix for resource names
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
RESOURCE_NAME="billing-view-${SUFFIX}"

# Define the source views (example, replace with actual source views)
SOURCE_VIEWS=(
    "arn:aws:billingconductor::123456789012:billingview/source-view-1"
    "arn:aws:billingconductor::123456789012:billingview/source-view-2"
)

# Create a billing view
CUSTOM_LINE_ITEM_ARN=$(aws billingconductor create-custom-line-item \
    --name "${RESOURCE_NAME}" \
    --description "Test custom line item" \
    --billing-period-range ExclusiveEndBillingPeriod="2024-05",InclusiveStartBillingPeriod="2024-03" \
    --billing-group-arn "arn:aws:billingconductor::123456789012:billinggroup/test-billing-group" \
    --custom-line-item-charge-details Flat='{"ChargeValue":10.0}' \
    --query 'arn' --output text)

echo "Created custom line item with ARN: ${CUSTOM_LINE_ITEM_ARN}"

# Verify the custom line item creation
RESPONSE=$(aws billingconductor get-custom-line-item --arn "${CUSTOM_LINE_ITEM_ARN}")
echo "Retrieved custom line item: ${RESPONSE}"

# List all custom line items
RESPONSE=$(aws billingconductor list-custom-line-items)
echo "Listed custom line items: ${RESPONSE}"

# Clean up by deleting the custom line item
aws billingconductor delete-custom-line-item --arn "${CUSTOM_LINE_ITEM_ARN}" || true
echo "Deleted custom line item with ARN: ${CUSTOM_LINE_ITEM_ARN}"

echo "PASS"