# GuardDuty: Enable threat detection and review findings

## Source

https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html

## Use case

- **ID**: guardduty/getting-started
- **Level**: beginner
- **Core actions**: `guardduty:CreateDetector`, `guardduty:ListFindings`, `guardduty:GetFindings`, `guardduty:CreateSampleFindings`

## Steps

1. Enable GuardDuty (handle pre-existing detector)
2. Get detector details
3. List findings
4. Generate sample findings
5. List findings again
6. Get finding statistics

## Resources created

| Resource | Type |
|----------|------|
| GuardDuty detector | `AWS::GuardDuty::Detector` |

## Duration

~13 seconds

## Cost

GuardDuty offers a free 30-day trial for new accounts. After the trial, pricing is based on the volume of data analyzed (VPC flow logs, DNS logs, CloudTrail events). The detector is deleted during cleanup.

## Related docs

- [Setting up GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html)
- [Understanding GuardDuty findings](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings.html)
- [Managing GuardDuty detectors](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_managing.html)
- [Sample findings](https://docs.aws.amazon.com/guardduty/latest/ug/sample_findings.html)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 97 |
| Exit code | 0 |
| Runtime | 13s |
| Steps | 6 |
| Issues | Handled pre-existing detector |
| Version | v1 |
