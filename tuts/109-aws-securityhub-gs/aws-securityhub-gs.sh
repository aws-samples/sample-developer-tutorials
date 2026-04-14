#!/bin/bash
# Tutorial: Enable AWS Security Hub and view security standards
# Source: https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/securityhub-$(date +%Y%m%d-%H%M%S).log"
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
        aws securityhub disable-security-hub 2>/dev/null && echo "  Disabled Security Hub"
    else
        echo "  Security Hub was already enabled — not disabling"
    fi
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Check/Enable Security Hub
echo "Step 1: Enabling Security Hub"
ENABLED=$(aws securityhub describe-hub --query 'HubArn' --output text 2>/dev/null || echo "NONE")
if [ "$ENABLED" != "NONE" ]; then
    echo "  Security Hub already enabled: $ENABLED"
    PREEXISTING=true
else
    aws securityhub enable-security-hub --enable-default-standards > /dev/null
    echo "  Security Hub enabled with default standards"
    PREEXISTING=false
    sleep 5
fi

# Step 2: List enabled standards
echo "Step 2: Enabled security standards"
aws securityhub get-enabled-standards \
    --query 'StandardsSubscriptions[].{Standard:StandardsArn,Status:StandardsStatus}' --output table

# Step 3: Describe hub
echo "Step 3: Hub details"
aws securityhub describe-hub \
    --query '{AutoEnable:AutoEnableControls,HubArn:HubArn}' --output table

# Step 4: List findings (top 5)
echo "Step 4: Recent findings (top 5)"
aws securityhub get-findings \
    --sort-criteria '{"Field":"SeverityNormalized","SortOrder":"desc"}' \
    --max-results 5 \
    --query 'Findings[].{Title:Title,Severity:Severity.Label,Status:Workflow.Status,Product:ProductName}' --output table 2>/dev/null || \
    echo "  No findings yet (Security Hub needs time to run checks)"

# Step 5: Get finding counts by severity
echo "Step 5: Finding statistics"
aws securityhub get-findings \
    --max-results 100 \
    --query 'Findings[].Severity.Label' --output text 2>/dev/null | tr '\t' '\n' | sort | uniq -c | sort -rn || \
    echo "  No findings available"

echo ""
echo "Tutorial complete."
if [ "$PREEXISTING" = true ]; then
    echo "Security Hub was already enabled — not disabling."
else
    echo "Do you want to clean up (disable Security Hub)? (y/n): "
    read -r CHOICE
    if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
        cleanup
    else
        echo "Security Hub remains enabled."
        echo "Manual cleanup: aws securityhub disable-security-hub"
    fi
fi
