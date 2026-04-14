# Backup: Create a vault and backup plan

## Source

https://docs.aws.amazon.com/aws-backup/latest/devguide/getting-started.html

## Use case

- **ID**: backup/getting-started
- **Level**: beginner
- **Core actions**: `backup:CreateBackupVault`, `backup:CreateBackupPlan`

## Steps

1. Create a backup vault
2. Create a backup plan (daily schedule, 30-day retention)
3. Describe the plan
4. List backup vaults
5. List backup plans

## Resources created

| Resource | Type |
|----------|------|
| `tut-vault-<random>` | Backup vault |
| `tut-plan-<random>` | Backup plan |

## Cost

No cost until a backup actually runs. This tutorial creates a plan and vault but does not execute a backup. AWS Backup pricing varies by resource type and storage amount.

## Duration

~6 seconds

## Related docs

- [Getting started with AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/getting-started.html)
- [Creating a backup plan](https://docs.aws.amazon.com/aws-backup/latest/devguide/creating-a-backup-plan.html)
- [AWS Backup pricing](https://aws.amazon.com/backup/pricing/)
- [Supported resources](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html#supported-resources)

---

## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 |
| Source script | New, 83 lines |
| Script test result | EXIT 0, 6s, 5 steps, suppressed delete-backup-plan JSON output |
| Issues encountered | None |
| Iterations | v1 |
