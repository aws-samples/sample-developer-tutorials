# CloudWatch Logs: Create log groups and query logs

## Source

https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html

## Use case

- **ID**: cloudwatch-logs/getting-started
- **Level**: beginner
- **Core actions**: `logs:CreateLogGroup`, `logs:PutLogEvents`, `logs:FilterLogEvents`, `logs:StartQuery`

## Steps

1. Create a log group
2. Set retention to 7 days
3. Create a log stream
4. Put 5 log events (INFO/WARN/ERROR)
5. Get log events
6. Filter for ERROR and WARN
7. Run a Logs Insights query

## Resources created

| Resource | Type |
|----------|------|
| `/tutorials/cloudwatch-logs-gs` | Log group |

## Cost

Negligible for 5 log events. All resources removed during cleanup.

## Duration

~14 seconds

## Related docs

- [What is Amazon CloudWatch Logs?](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html)
- [CloudWatch Logs Insights query syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
- [Filter and pattern syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 91 |
| Exit code | 0 |
| Runtime | 14s |
| Steps | 7 |
| Issues | None |
| Version | v1 |
