# Config: Add a rule and check compliance

## Source

https://docs.aws.amazon.com/config/latest/developerguide/getting-started.html

## Use case

- **ID**: config/getting-started
- **Level**: intermediate
- **Core actions**: `configservice:PutConfigRule`, `configservice:GetComplianceDetailsByConfigRule`

## Prerequisites

An existing AWS Config recorder must be enabled in your account. Only one recorder is allowed per account per Region. The tutorial checks for a running recorder and exits if none is found.

## Steps

1. Check Config recorder status
2. List discovered S3 buckets
3. Add a managed rule (S3 encryption check)
4. Trigger rule evaluation
5. Check compliance details
6. View compliance summary

## Resources created

| Resource | Type |
|----------|------|
| `tut-s3-encryption-<random>` | Config rule |

## Cost

No additional cost for managed Config rules if you already have a recorder running. Config charges per rule evaluation ($0.001 per evaluation in most Regions). The rule is deleted during cleanup.

## Duration

~36 seconds (includes 30-second wait for rule evaluation)

## Related docs

- [Getting started with AWS Config](https://docs.aws.amazon.com/config/latest/developerguide/getting-started.html)
- [AWS Config managed rules](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html)
- [Evaluating resources](https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html)
- [AWS Config pricing](https://aws.amazon.com/config/pricing/)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 83 |
| Exit code | 0 |
| Runtime | 36s |
| Steps | 6 |
| Issues | Rewritten to use existing recorder (only 1 allowed per account) |
| Version | v1 |
