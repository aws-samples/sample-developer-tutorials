# CloudWatch: Create alarms and dashboards

## Source

https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/GettingStarted.html

## Use case

- **ID**: cloudwatch/getting-started
- **Level**: beginner
- **Core actions**: `cloudwatch:PutMetricData`, `cloudwatch:PutMetricAlarm`

## Steps

1. Publish custom metrics
2. Retrieve metric statistics
3. Create an alarm
4. Describe the alarm
5. Create a dashboard
6. List dashboards

## Resources created

| Resource | Type |
|----------|------|
| `tut-alarm-<random>` | CloudWatch alarm |
| `tut-dashboard-<random>` | CloudWatch dashboard |
| `Tutorial/App` | Custom metric namespace |

## Cost

Free tier includes 10 alarms and 3 dashboards. This tutorial creates 1 alarm and 1 dashboard.

## Duration

~12 seconds

## Related docs

- [Getting started with CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/GettingStarted.html)
- [Using Amazon CloudWatch alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
- [Using CloudWatch dashboards](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Dashboards.html)
- [Publishing custom metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 99 |
| Exit code | 0 |
| Runtime | 12s |
| Steps | 6 |
| Issues | None |
| Version | v1 |
