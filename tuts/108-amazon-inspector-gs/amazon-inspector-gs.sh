#!/bin/bash
# Tutorial: Enable Amazon Inspector and view findings
# Source: https://docs.aws.amazon.com/inspector/latest/user/getting_started_tutorial.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/inspector-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    if [ "$PREEXISTING" != true ]; then
        aws inspector2 disable --resource-types EC2 ECR LAMBDA > /dev/null 2>&1 && \
            echo "  Disabled Inspector"
    else
        echo "  Inspector was already enabled — not disabling"
    fi
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Check/Enable Inspector
echo "Step 1: Enabling Amazon Inspector"
STATUS=$(aws inspector2 batch-get-account-status \
    --query 'accounts[0].state.status' --output text 2>/dev/null || echo "DISABLED")
if [ "$STATUS" = "ENABLED" ]; then
    echo "  Inspector already enabled"
    PREEXISTING=true
else
    aws inspector2 enable --resource-types EC2 ECR LAMBDA > /dev/null
    echo "  Inspector enabled for EC2, ECR, and Lambda"
    PREEXISTING=false
    sleep 5
fi

# Step 2: Get account status
echo "Step 2: Account status"
aws inspector2 batch-get-account-status \
    --query 'accounts[0].{Status:state.status,EC2:resourceState.ec2.status,ECR:resourceState.ecr.status,Lambda:resourceState.lambda.status}' --output table

# Step 3: List findings
echo "Step 3: Listing findings (top 5 by severity)"
aws inspector2 list-findings \
    --sort-criteria '{"field":"SEVERITY","sortOrder":"DESC"}' \
    --max-results 5 \
    --query 'findings[].{Title:title,Severity:severity,Type:type,Status:status}' --output table 2>/dev/null || \
    echo "  No findings yet (Inspector needs time to scan resources)"

# Step 4: Get finding counts by severity
echo "Step 4: Finding counts"
aws inspector2 list-finding-aggregations \
    --aggregation-type SEVERITY \
    --query 'responses[].{Severity:severityCounts}' --output json 2>/dev/null | python3 -m json.tool 2>/dev/null || \
    echo "  No aggregation data available yet"

# Step 5: Get coverage statistics
echo "Step 5: Coverage statistics"
aws inspector2 list-coverage-statistics \
    --query 'countsByGroup[].{ResourceType:groupKey,Count:count}' --output table 2>/dev/null || \
    echo "  No coverage data available yet"

echo ""
echo "Tutorial complete."
if [ "$PREEXISTING" = true ]; then
    echo "Inspector was already enabled — not disabling."
else
    echo "Do you want to clean up (disable Inspector)? (y/n): "
    read -r CHOICE
    if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
        cleanup
    else
        echo "Inspector remains enabled. It will scan resources automatically."
        echo "Manual cleanup: aws inspector2 disable --resource-types EC2 ECR LAMBDA"
    fi
fi
