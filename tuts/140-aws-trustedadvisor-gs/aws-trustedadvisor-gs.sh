#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/ta.log") 2>&1
export AWS_DEFAULT_REGION=us-east-1; echo "Region: us-east-1 (Trusted Advisor is global)"
echo "Step 1: Listing checks"
aws support describe-trusted-advisor-checks --language en --query 'checks[:10].{Id:id,Name:name,Category:category}' --output table 2>/dev/null || echo "  Trusted Advisor requires Business or Enterprise Support plan"
echo "Step 2: Getting check results"
aws support describe-trusted-advisor-check-result --check-id Pfx0RwqBli --query 'result.{Status:status,ResourcesSummary:resourcesSummary}' --output table 2>/dev/null || echo "  Cannot get results (requires Support plan)"
echo ""; echo "Tutorial complete. No resources created — Trusted Advisor is read-only."
rm -rf "$WORK_DIR"
