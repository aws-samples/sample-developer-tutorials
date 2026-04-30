# Create a backup vault and backup plan with AWS Backup

This tutorial shows you how to create a backup vault, create a backup plan with a daily schedule and 30-day retention, inspect the plan details, and list your vaults and plans.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions for `backup:CreateBackupVault`, `backup:DeleteBackupVault`, `backup:CreateBackupPlan`, `backup:DeleteBackupPlan`, `backup:GetBackupPlan`, `backup:ListBackupVaults`, `backup:ListBackupPlans`

## Step 1: Create a backup vault

Create a vault to store recovery points.

```bash
VAULT_NAME="tut-vault-$(openssl rand -hex 4)"

aws backup create-backup-vault --backup-vault-name "$VAULT_NAME" \
    --query 'BackupVaultArn' --output text
```

A backup vault is a container for recovery points (backups). Each vault has its own encryption key and access policy. The default vault uses the AWS managed key for Backup.

## Step 2: Create a backup plan

Create a plan with a daily backup rule that targets the vault and retains backups for 30 days.

```bash
PLAN_NAME="tut-plan-$(openssl rand -hex 4)"

PLAN_RESULT=$(aws backup create-backup-plan --backup-plan "{
    \"BackupPlanName\":\"$PLAN_NAME\",
    \"Rules\":[{
        \"RuleName\":\"DailyBackup\",
        \"TargetBackupVaultName\":\"$VAULT_NAME\",
        \"ScheduleExpression\":\"cron(0 12 * * ? *)\",
        \"StartWindowMinutes\":60,
        \"CompletionWindowMinutes\":180,
        \"Lifecycle\":{\"DeleteAfterDays\":30}
    }]
}")
PLAN_ID=$(echo "$PLAN_RESULT" | python3 -c "import sys,json;print(json.load(sys.stdin)['BackupPlanId'])")
```

`ScheduleExpression` uses a cron expression — this one runs daily at noon UTC. `StartWindowMinutes` is how long Backup waits before canceling a job that hasn't started. `Lifecycle` controls retention.

## Step 3: Describe the plan

View the plan details and rule configuration.

```bash
aws backup get-backup-plan --backup-plan-id "$PLAN_ID" \
    --query 'BackupPlan.{Name:BackupPlanName,Rules:Rules[0].{Rule:RuleName,Schedule:ScheduleExpression,Retention:Lifecycle.DeleteAfterDays}}' \
    --output table
```

A plan can have multiple rules targeting different vaults or schedules. Each rule can also specify copy actions to replicate backups to another Region.

## Step 4: List backup vaults

List vaults in your account.

```bash
aws backup list-backup-vaults \
    --query 'BackupVaultList[].{Name:BackupVaultName,Created:CreationDate,RecoveryPoints:NumberOfRecoveryPoints}' \
    --output table
```

Every account has a `Default` vault created automatically. The tutorial vault will show zero recovery points since no backup has run yet.

## Step 5: List backup plans

List plans in your account.

```bash
aws backup list-backup-plans \
    --query 'BackupPlansList[].{Name:BackupPlanName,Id:BackupPlanId,Created:CreationDate}' \
    --output table
```

Plans are independent of resource assignments. To actually back up resources, you create a backup selection that assigns resources (by ARN or tag) to a plan.

## Cleanup

Delete the backup plan and vault:

```bash
aws backup delete-backup-plan --backup-plan-id "$PLAN_ID"
aws backup delete-backup-vault --backup-vault-name "$VAULT_NAME"
```

No actual backup ran during this tutorial, so there is no cost. AWS Backup charges only when backups are stored — pricing varies by resource type and storage amount. Deleting the plan stops future scheduled backups, and deleting an empty vault is immediate.

The script automates all steps including cleanup:

```bash
bash aws-backup-gs.sh
```

## Related resources

- [Getting started with AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/getting-started.html)
- [Creating a backup plan](https://docs.aws.amazon.com/aws-backup/latest/devguide/creating-a-backup-plan.html)
- [AWS Backup pricing](https://aws.amazon.com/backup/pricing/)
- [Supported resources](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html#supported-resources)
