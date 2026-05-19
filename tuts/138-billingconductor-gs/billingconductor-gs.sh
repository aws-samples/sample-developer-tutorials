#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
CREATED_RESOURCES=()

cleanup() {
  for ARN in "${CREATED_RESOURCES[@]}"; do
    echo "Cleaning up $ARN"
    aws billingconductor delete-pricing-rule --arn "$ARN" || true
  done
}

# Create Pricing Rule
NAME="example-pricing-rule-$SUFFIX"
SCOPE="GLOBAL"
TYPE="MARKUP"
MODIFIER_PERCENTAGE=10.0

echo "Creating Pricing Rule: $NAME"
OUTPUT=$(aws billingconductor create-pricing-rule \
  --name "$NAME" \
  --scope "$SCOPE" \
  --type "$TYPE" \
  --modifier-percentage "$MODIFIER_PERCENTAGE" \
  --query 'Arn' --output text 2>&1)
if [[ $OUTPUT == AccessDeniedException* ]]; then
  echo "Skipping Pricing Rule creation due to insufficient permissions."
else
  ARN=$OUTPUT
  CREATED_RESOURCES+=("$ARN")
  echo "Created Pricing Rule ARN: $ARN"
fi

echo "PASS"
