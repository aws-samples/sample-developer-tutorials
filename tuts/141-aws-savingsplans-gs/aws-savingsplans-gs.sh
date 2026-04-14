#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/sp.log") 2>&1
export AWS_DEFAULT_REGION=us-east-1; echo "Region: us-east-1"
echo "Step 1: Describing savings plans"
aws savingsplans describe-savings-plans --query 'savingsPlans[:5].{Id:savingsPlanId,Type:savingsPlanType,State:state,Commitment:commitment}' --output table 2>/dev/null || echo "  No savings plans found"
echo "Step 2: Describing savings plan rates"
aws savingsplans describe-savings-plans-offering-rates --savings-plan-offering-ids [] 2>/dev/null | head -5 || echo "  No offering rates (no active plans)"
echo "Step 3: Listing available offerings"
aws savingsplans describe-savings-plans-offerings --query 'searchResults[:3].{Type:planType,Duration:durationSeconds,Currency:currency}' --output table 2>/dev/null || echo "  Cannot list offerings"
echo ""; echo "Tutorial complete. No resources created — read-only."
rm -rf "$WORK_DIR"
