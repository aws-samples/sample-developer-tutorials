# Inspector: Enable scanning and view findings

Enable Amazon Inspector for EC2, ECR, and Lambda scanning, view findings by severity, and check coverage statistics.

## Source

https://docs.aws.amazon.com/inspector/latest/user/getting_started_tutorial.html

## Use case

- ID: inspector/getting-started
- Phase: create
- Complexity: beginner
- Core actions: inspector2:Enable, inspector2:BatchGetAccountStatus, inspector2:ListFindings

## What it does

1. Enables Inspector for EC2, ECR, and Lambda (handles pre-existing)
2. Gets account scanning status
3. Lists findings by severity
4. Gets finding counts by severity
5. Gets coverage statistics

## Running

```bash
bash amazon-inspector-gs.sh
```

## Resources created

| Resource | Type |
|----------|------|
| Inspector enablement | Service activation (EC2, ECR, Lambda) |

## Estimated time

- Run: ~11 seconds

## Cost

Free 15-day trial for new accounts. After the trial, pricing is based on the number of resources scanned. Cleanup disables Inspector to stop charges.

## Related docs

- [Getting started with Amazon Inspector](https://docs.aws.amazon.com/inspector/latest/user/getting_started_tutorial.html)
- [Understanding findings](https://docs.aws.amazon.com/inspector/latest/user/findings-understanding.html)
- [Managing coverage](https://docs.aws.amazon.com/inspector/latest/user/managing-coverage.html)
- [Amazon Inspector pricing](https://aws.amazon.com/inspector/pricing/)
