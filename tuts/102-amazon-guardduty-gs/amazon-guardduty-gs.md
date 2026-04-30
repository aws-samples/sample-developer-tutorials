# Enable Amazon GuardDuty and review findings

This tutorial shows you how to enable Amazon GuardDuty, inspect the detector configuration, generate sample findings, and review finding details and statistics.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions for `guardduty:CreateDetector`, `guardduty:GetDetector`, `guardduty:ListFindings`, `guardduty:GetFindings`, `guardduty:CreateSampleFindings`, `guardduty:GetFindingsStatistics`, `guardduty:ListDetectors`, and `guardduty:DeleteDetector`

## Step 1: Enable GuardDuty

Check whether GuardDuty is already enabled in the current region. If a detector exists, use it. Otherwise, create one.

```bash
EXISTING=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)

if [ "$EXISTING" != "None" ] && [ -n "$EXISTING" ]; then
    DETECTOR_ID="$EXISTING"
    echo "GuardDuty already enabled. Detector: $DETECTOR_ID"
else
    DETECTOR_ID=$(aws guardduty create-detector --enable \
        --query 'DetectorId' --output text)
    echo "Detector created: $DETECTOR_ID"
fi
```

GuardDuty allows only one detector per region per account. If you already have one, the script reuses it and skips deletion during cleanup.

## Step 2: Get detector details

```bash
aws guardduty get-detector --detector-id "$DETECTOR_ID" \
    --query '{Status:Status,Created:CreatedAt,Updated:UpdatedAt}' --output table
```

The detector status should be `ENABLED`. GuardDuty begins analyzing VPC flow logs, DNS logs, and CloudTrail events immediately.

## Step 3: List findings

```bash
FINDING_IDS=$(aws guardduty list-findings --detector-id "$DETECTOR_ID" \
    --max-results 5 --query 'FindingIds' --output json)
echo "$FINDING_IDS"
```

A new detector has no findings yet. After generating sample findings in the next step, this list will be populated.

## Step 4: Generate sample findings

Create sample findings to see what GuardDuty detections look like without waiting for real threats.

```bash
aws guardduty create-sample-findings --detector-id "$DETECTOR_ID" \
    --finding-types "Recon:EC2/PortProbeUnprotectedPort" "UnauthorizedAccess:EC2/SSHBruteForce"
sleep 5
```

Sample findings are marked with `[SAMPLE]` in the title. The `sleep` gives GuardDuty time to process them.

## Step 5: List findings again

```bash
FINDING_IDS=$(aws guardduty list-findings --detector-id "$DETECTOR_ID" \
    --max-results 5 --query 'FindingIds' --output json)

aws guardduty get-findings --detector-id "$DETECTOR_ID" \
    --finding-ids $FINDING_IDS \
    --query 'Findings[:3].{Type:Type,Severity:Severity,Title:Title}' --output table
```

Each finding includes a type (such as `Recon:EC2/PortProbeUnprotectedPort`), a severity from 0 to 10, and a human-readable title.

## Step 6: Get finding statistics

```bash
aws guardduty get-findings-statistics --detector-id "$DETECTOR_ID" \
    --finding-statistic-types COUNT_BY_SEVERITY \
    --query 'FindingStatistics.CountBySeverity' --output table
```

The statistics group findings by severity level, giving you a quick overview of your security posture.

## Cleanup

If you created the detector in this tutorial, delete it. If the detector was pre-existing, leave it in place.

```bash
aws guardduty delete-detector --detector-id "$DETECTOR_ID"
```

Deleting the detector disables GuardDuty and removes all findings in the region. If you had a pre-existing detector, archive the sample findings from the GuardDuty console instead.

The script automates all steps including cleanup:

```bash
bash amazon-guardduty-gs.sh
```

## Related resources

- [Setting up GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html)
- [Understanding GuardDuty findings](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings.html)
- [Managing GuardDuty detectors](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_managing.html)
- [Sample findings](https://docs.aws.amazon.com/guardduty/latest/ug/sample_findings.html)
