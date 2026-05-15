# Tutorial: Managing AWS Security Hub with CLI

## Prerequisites

- An AWS account.
- AWS CLI installed and configured with appropriate permissions.

## Steps

**1. Enable Security Hub**

```bash
$ aws securityhub enable-security-hub --enable-default-standards
```

This command enables AWS Security Hub and applies default standards. If Security Hub is already enabled, it outputs "Already enabled".

**2. Get Findings**

```bash
$ aws securityhub get-findings --max-results 3 --query 'Findings[].Title' --output text
```

Retrieve up to three findings from Security Hub. If no findings are available, it outputs "No findings".

**3. Disable Security Hub**

```bash
$ aws securityhub disable-security-hub
```

This command disables AWS Security Hub.

## Clean up

After completing the tutorial, the script automatically cleans up by removing temporary files and logging the cleanup of resources.

## Next steps

- Explore Security Hub findings in detail.
- Set up automated responses to findings.
- Integrate Security Hub with other AWS services for enhanced security monitoring.
