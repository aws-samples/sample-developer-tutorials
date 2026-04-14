# Enable and view security standards with AWS Security Hub

This tutorial shows you how to enable AWS Security Hub with default security standards, list enabled standards, view hub configuration, list findings by severity, and get finding statistics.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions for `securityhub:EnableSecurityHub`, `securityhub:DisableSecurityHub`, `securityhub:DescribeHub`, `securityhub:GetEnabledStandards`, `securityhub:GetFindings`

## Step 1: Enable Security Hub

Enable Security Hub with default security standards. If Security Hub is already enabled, the script detects this and skips enablement.

```bash
ENABLED=$(aws securityhub describe-hub \
    --query 'HubArn' --output text 2>/dev/null || echo "NONE")

if [ "$ENABLED" != "NONE" ]; then
    echo "Security Hub already enabled: $ENABLED"
else
    aws securityhub enable-security-hub --enable-default-standards
fi
```

Enabling with `--enable-default-standards` automatically subscribes you to the AWS Foundational Security Best Practices standard and CIS AWS Foundations Benchmark.

## Step 2: List enabled standards

View which security standards are active in your account.

```bash
aws securityhub get-enabled-standards \
    --query 'StandardsSubscriptions[].{Standard:StandardsArn,Status:StandardsStatus}' \
    --output table
```

Each standard contains a set of security controls. Standards take a few minutes to finish their initial evaluation.

## Step 3: Describe hub

Check the hub configuration.

```bash
aws securityhub describe-hub \
    --query '{AutoEnable:AutoEnableControls,HubArn:HubArn}' \
    --output table
```

`AutoEnableControls` indicates whether new controls are automatically enabled when a standard is updated.

## Step 4: List findings by severity

List the most severe findings across all enabled standards.

```bash
aws securityhub get-findings \
    --sort-criteria '{"Field":"SeverityNormalized","SortOrder":"desc"}' \
    --max-results 5 \
    --query 'Findings[].{Title:Title,Severity:Severity.Label,Status:Workflow.Status,Product:ProductName}' \
    --output table
```

Security Hub normalizes severity across all integrated products to CRITICAL, HIGH, MEDIUM, LOW, and INFORMATIONAL.

## Step 5: Get finding statistics

Count findings by severity level.

```bash
aws securityhub get-findings \
    --max-results 100 \
    --query 'Findings[].Severity.Label' --output text \
    | tr '\t' '\n' | sort | uniq -c | sort -rn
```

This retrieves up to 100 findings and counts them by severity label. For accounts with many findings, use `--filters` to narrow the scope.

## Cleanup

If you enabled Security Hub during this tutorial, disable it:

```bash
aws securityhub disable-security-hub
```

If Security Hub was already enabled before the tutorial, the script leaves it running.

Security Hub offers a free 30-day trial for new accounts. After the trial, you pay based on the number of security checks and finding ingestion events. Disabling stops all checks and future charges.

The script automates all steps including cleanup:

```bash
bash aws-securityhub-gs.sh
```

## Related resources

- [Setting up Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html)
- [Security standards in Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html)
- [Viewing findings](https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-findings-viewing.html)
- [AWS Security Hub pricing](https://aws.amazon.com/security-hub/pricing/)
