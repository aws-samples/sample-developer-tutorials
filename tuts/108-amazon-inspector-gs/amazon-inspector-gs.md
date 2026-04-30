# Enable scanning and view findings with Amazon Inspector

This tutorial shows you how to enable Amazon Inspector for EC2, ECR, and Lambda scanning, check account status, list findings by severity, view finding counts, and get coverage statistics.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions for `inspector2:Enable`, `inspector2:Disable`, `inspector2:BatchGetAccountStatus`, `inspector2:ListFindings`, `inspector2:ListFindingAggregations`, `inspector2:ListCoverageStatistics`

## Step 1: Enable Inspector

Enable Inspector for EC2 instances, ECR container images, and Lambda functions. If Inspector is already enabled, the script detects this and skips enablement.

```bash
STATUS=$(aws inspector2 batch-get-account-status \
    --query 'accounts[0].state.status' --output text 2>/dev/null || echo "DISABLED")

if [ "$STATUS" = "ENABLED" ]; then
    echo "Inspector already enabled"
else
    aws inspector2 enable --resource-types EC2 ECR LAMBDA
fi
```

When you enable Inspector, it automatically begins scanning supported resources. New EC2 instances, ECR images, and Lambda functions are scanned as they appear.

## Step 2: Get account status

Check the scanning status for each resource type.

```bash
aws inspector2 batch-get-account-status \
    --query 'accounts[0].{Status:state.status,EC2:resourceState.ec2.status,ECR:resourceState.ecr.status,Lambda:resourceState.lambda.status}' \
    --output table
```

Each resource type has its own status. All three should show `ENABLED` after activation.

## Step 3: List findings by severity

List the top findings sorted by severity.

```bash
aws inspector2 list-findings \
    --sort-criteria '{"field":"SEVERITY","sortOrder":"DESC"}' \
    --max-results 5 \
    --query 'findings[].{Title:title,Severity:severity,Type:type,Status:status}' \
    --output table
```

Inspector generates findings for software vulnerabilities and unintended network exposure. Findings appear as Inspector completes its initial scan, which may take several minutes.

## Step 4: Get finding counts

View aggregated finding counts by severity level.

```bash
aws inspector2 list-finding-aggregations \
    --aggregation-type SEVERITY \
    --query 'responses[].{Severity:severityCounts}' \
    --output json
```

## Step 5: Get coverage statistics

Check how many resources Inspector is scanning.

```bash
aws inspector2 list-coverage-statistics \
    --query 'countsByGroup[].{ResourceType:groupKey,Count:count}' \
    --output table
```

Coverage statistics show the number of resources being scanned, grouped by resource type.

## Cleanup

If you enabled Inspector during this tutorial, disable it to stop scanning:

```bash
aws inspector2 disable --resource-types EC2 ECR LAMBDA
```

If Inspector was already enabled before the tutorial, the script leaves it running.

Inspector offers a free 15-day trial for new accounts. After the trial, you pay based on the number of resources scanned. Disabling stops all scanning and future charges.

The script automates all steps including cleanup:

```bash
bash amazon-inspector-gs.sh
```

## Related resources

- [Getting started with Amazon Inspector](https://docs.aws.amazon.com/inspector/latest/user/getting_started_tutorial.html)
- [Understanding findings](https://docs.aws.amazon.com/inspector/latest/user/findings-understanding.html)
- [Managing coverage](https://docs.aws.amazon.com/inspector/latest/user/managing-coverage.html)
- [Amazon Inspector pricing](https://aws.amazon.com/inspector/pricing/)
