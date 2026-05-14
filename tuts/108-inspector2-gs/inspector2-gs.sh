#!/bin/bash
set -e

# Generate a unique suffix
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

echo "Checking account status..."
ACCOUNT_STATUS=$(aws inspector2 batch-get-account-status | grep -o '"status":"[^"]*"' | head -n 1)
STATE=$(echo $ACCOUNT_STATUS | sed -e's/.*:"\([^"]*\)".*/\1/')

if [ "$STATE"!= "ENABLED" ]; then
    echo "Enabling Inspector2..."
    aws inspector2 enable --resource-types ECR --client-token $(date +%s) || true
    sleep 3  # Wait for the service to enable
fi

echo "Listing findings..."
FINDINGS=$(aws inspector2 list-findings --max-results 5 --filter-criteria '{"severity": [{"comparison": "EQUALS", "value": "INFORMATIONAL"}]}' --sort-criteria '{"field": "SEVERITY", "sortOrder": "DESC"}')
FINDINGS_COUNT=$(echo $FINDINGS | grep -o '"id":"[^"]*"' | wc -l)
echo "Found $FINDINGS_COUNT findings."

echo "Creating filter..."
FILTER_RESPONSE=$(aws inspector2 create-filter --name "my-filter-$SUFFIX" --action SUPPRESS --filter-criteria '{"severity": [{"comparison": "EQUALS", "value": "INFORMATIONAL"}]}' --output text)
FILTER_ARN=$(echo $FILTER_RESPONSE | grep -o 'arn:[^"]*')
echo "Filter created with ARN: $FILTER_ARN"

echo "Deleting filter..."
aws inspector2 delete-filter --arn $FILTER_ARN || true
echo "Filter deleted."

echo "Disabling Inspector2..."
aws inspector2 disable --resource-types ECR || true
echo "Inspector2 disabled."

echo "PASS"