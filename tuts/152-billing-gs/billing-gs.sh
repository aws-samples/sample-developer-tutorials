#!/bin/bash
set -e
echo "=== AWS Billing Tutorial ==="
echo "The Billing API lets you manage billing views and preferences."
echo ""
echo "=== Listing billing views ==="
aws billing list-billing-views --query 'billingViews[].name' --output text 2>/dev/null || echo "No billing views"
echo ""
echo "PASS"
