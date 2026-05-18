#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
UNIQUE_ID="doc-smith-${SUFFIX}"

echo "Attempting to describe Savings Plans Offerings"
OFFERINGS=$(aws savingsplans describe-savings-plans-offerings --query 'SavingsPlansOfferings[*].SavingsPlanOfferingId' --output text)
if [ -n "$OFFERINGS" ]; then
    echo "Described Savings Plans Offerings: $OFFERINGS"
else
    echo "No Savings Plan Offerings found."
    exit 1
fi

echo "PASS"