#!/bin/bash
set -e

# Generate a unique suffix for resource names
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
UNIQUE_ID="doc-smith-${SUFFIX}"

# Step 1: Describe Savings Plans Offerings
SAVINGS_PLAN_OFFERING_ID=$(aws savingsplans describe-savings-plans-offerings --query 'SavingsPlansOfferings[0].SavingsPlanOfferingId' --output text)
if [ -z "$SAVINGS_PLAN_OFFERING_ID" ]; then
    echo "No Savings Plan Offerings found."
    exit 1
fi
echo "Selected Savings Plan Offering ID: $SAVINGS_PLAN_OFFERING_ID"

# Step 2: Create a Savings Plan
SAVINGS_PLAN_ID=$(aws savingsplans create-savings-plan --savings-plan-offering-id "$SAVINGS_PLAN_OFFERING_ID" --commitment '2000' --client-token "$(uuidgen)" --query 'savingsPlanId' --output text)
if [ -z "$SAVINGS_PLAN_ID" ]; then
    echo "Failed to create Savings Plan."
    exit 1
fi
echo "Created Savings Plan ID: $SAVINGS_PLAN_ID"

# Step 3: Describe Savings Plans
aws savingsplans describe-savings-plans --savings-plan-ids "$SAVINGS_PLAN_ID"

# Step 4: Describe Savings Plan Rates
aws savingsplans describe-savings-plan-rates --savings-plan-id "$SAVINGS_PLAN_ID"

# Step 5: Describe Savings Plans Offering Rates
aws savingsplans describe-savings-plans-offering-rates --savings-plan-offering-ids "$SAVINGS_PLAN_OFFERING_ID"

# Step 6: List Tags for Resource
aws savingsplans list-tags-for-resource --resource-arn "arn:aws:savingsplans:us-east-1:559823168634:savingsplan/$SAVINGS_PLAN_ID"

# Step 7: Clean up - Delete the Savings Plan
aws savingsplans delete-queued-savings-plan --savings-plan-id "$SAVINGS_PLAN_ID" || true

echo "PASS"