#!/bin/bash
# Tutorial: Enable Amazon GuardDuty and review findings
# Source: https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/guardduty-$(date +%Y%m%d-%H%M%S).log"
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
    [ -n "$DETECTOR_ID" ] && aws guardduty delete-detector --detector-id "$DETECTOR_ID" 2>/dev/null && \
        echo "  Deleted detector $DETECTOR_ID"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Enable GuardDuty
echo "Step 1: Enabling GuardDuty"
EXISTING=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text 2>/dev/null)
if [ -n "$EXISTING" ] && [ "$EXISTING" != "None" ]; then
    echo "  GuardDuty already enabled. Detector: $EXISTING"
    DETECTOR_ID="$EXISTING"
    PREEXISTING=true
else
    DETECTOR_ID=$(aws guardduty create-detector --enable \
        --query 'DetectorId' --output text)
    echo "  Detector created: $DETECTOR_ID"
    PREEXISTING=false
fi

# Step 2: Get detector details
echo "Step 2: Detector details"
aws guardduty get-detector --detector-id "$DETECTOR_ID" \
    --query '{Status:Status,Created:CreatedAt,Updated:UpdatedAt}' --output table

# Step 3: List findings
echo "Step 3: Listing findings"
FINDING_IDS=$(aws guardduty list-findings --detector-id "$DETECTOR_ID" \
    --max-results 5 --query 'FindingIds' --output json)
FINDING_COUNT=$(echo "$FINDING_IDS" | python3 -c "import sys,json;print(len(json.load(sys.stdin)))")
echo "  Found $FINDING_COUNT findings"

if [ "$FINDING_COUNT" -gt 0 ]; then
    echo "Step 3b: Finding details"
    aws guardduty get-findings --detector-id "$DETECTOR_ID" \
        --finding-ids "$FINDING_IDS" \
        --query 'Findings[].{Type:Type,Severity:Severity,Title:Title}' --output table
fi

# Step 4: Generate sample findings
echo "Step 4: Generating sample findings"
aws guardduty create-sample-findings --detector-id "$DETECTOR_ID" \
    --finding-types "Recon:EC2/PortProbeUnprotectedPort" "UnauthorizedAccess:EC2/SSHBruteForce"
echo "  Sample findings generated"
sleep 5

# Step 5: List findings again
echo "Step 5: Listing findings (with samples)"
FINDING_IDS=$(aws guardduty list-findings --detector-id "$DETECTOR_ID" \
    --max-results 5 --query 'FindingIds' --output json)
aws guardduty get-findings --detector-id "$DETECTOR_ID" \
    --finding-ids $FINDING_IDS \
    --query 'Findings[:3].{Type:Type,Severity:Severity,Title:Title}' --output table

# Step 6: Get finding statistics
echo "Step 6: Finding statistics by severity"
aws guardduty get-findings-statistics --detector-id "$DETECTOR_ID" \
    --finding-statistic-types COUNT_BY_SEVERITY \
    --query 'FindingStatistics.CountBySeverity' --output table 2>/dev/null || echo "  No statistics available"

echo ""
echo "Tutorial complete."
if [ "$PREEXISTING" = true ]; then
    echo "GuardDuty was already enabled — not deleting the detector."
    echo "To archive sample findings: use the GuardDuty console."
else
    echo "Do you want to clean up all resources? (y/n): "
    read -r CHOICE
    if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
        cleanup
    else
        echo "Manual cleanup:"
        echo "  aws guardduty delete-detector --detector-id $DETECTOR_ID"
    fi
fi
