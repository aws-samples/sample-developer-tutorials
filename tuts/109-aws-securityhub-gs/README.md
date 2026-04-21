# Security Hub: Enable and view security standards

Enable AWS Security Hub with default standards, list enabled standards, view findings by severity, and get finding statistics.

## Source

https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html

## Use case

- ID: securityhub/getting-started
- Phase: create
- Complexity: beginner
- Core actions: securityhub:EnableSecurityHub, securityhub:GetEnabledStandards, securityhub:GetFindings

## What it does

1. Enables Security Hub with default standards (handles pre-existing)
2. Lists enabled security standards
3. Describes hub configuration
4. Lists findings by severity
5. Gets finding statistics by severity level

## Running

```bash
bash aws-securityhub-gs.sh
```

## Resources created

| Resource | Type |
|----------|------|
| Security Hub enablement | Service activation (with default standards) |

## Estimated time

- Run: ~12 seconds

## Cost

Free 30-day trial for new accounts. After the trial, pricing is based on security checks and finding ingestion events. Cleanup disables Security Hub to stop charges.

## Related docs

- [Setting up Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-settingup.html)
- [Security standards in Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards.html)
- [Viewing findings](https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-findings-viewing.html)
- [AWS Security Hub pricing](https://aws.amazon.com/security-hub/pricing/)
