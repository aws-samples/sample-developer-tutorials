#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
UNIQUE_ID="doc-smith-${SUFFIX}"
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/log.txt"
CREATED_RESOURCES=()

cleanup_resources() {
    for ARN in "${CREATED_RESOURCES[@]}"; do
        aws tag-resource --resource-arn "$ARN" --tags project=doc-smith tutorial=savingsplans-gs
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

echo "Step 1: Describe Savings Plans Offerings" >> "$LOG_FILE"
OFFERINGS=$(aws savingsplans describe-savings-plans-offerings --query 'SavingsPlansOfferings[*].SavingsPlanOfferingId' --output text)
if [ -n "$OFFERINGS" ]; then
    echo "Described Savings Plans Offerings: $OFFERINGS" >> "$LOG_FILE"
else
    echo "No Savings Plan Offerings found." >> "$LOG_FILE"
    exit 1
fi

echo "PASS" >> "$LOG_FILE"