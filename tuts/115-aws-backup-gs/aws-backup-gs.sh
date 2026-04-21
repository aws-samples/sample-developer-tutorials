#!/bin/bash
# Tutorial: Create a backup vault and backup plan with AWS Backup
# Source: https://docs.aws.amazon.com/aws-backup/latest/devguide/getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/backup-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
VAULT_NAME="tut-vault-${RANDOM_ID}"
PLAN_NAME="tut-plan-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    [ -n "$PLAN_ID" ] && aws backup delete-backup-plan --backup-plan-id "$PLAN_ID" > /dev/null 2>&1 && \
        echo "  Deleted backup plan $PLAN_NAME"
    aws backup delete-backup-vault --backup-vault-name "$VAULT_NAME" 2>/dev/null && \
        echo "  Deleted vault $VAULT_NAME"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a backup vault
echo "Step 1: Creating backup vault: $VAULT_NAME"
aws backup create-backup-vault --backup-vault-name "$VAULT_NAME" \
    --query 'BackupVaultArn' --output text
echo "  Vault created"

# Step 2: Create a backup plan
echo "Step 2: Creating backup plan: $PLAN_NAME"
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
echo "  Plan ID: $PLAN_ID"

# Step 3: Describe the plan
echo "Step 3: Backup plan details"
aws backup get-backup-plan --backup-plan-id "$PLAN_ID" \
    --query 'BackupPlan.{Name:BackupPlanName,Rules:Rules[0].{Rule:RuleName,Schedule:ScheduleExpression,Retention:Lifecycle.DeleteAfterDays}}' --output table

# Step 4: List backup vaults
echo "Step 4: Listing backup vaults"
aws backup list-backup-vaults \
    --query 'BackupVaultList[?starts_with(BackupVaultName, `tut-`)].{Name:BackupVaultName,Created:CreationDate,RecoveryPoints:NumberOfRecoveryPoints}' --output table

# Step 5: List backup plans
echo "Step 5: Listing backup plans"
aws backup list-backup-plans \
    --query 'BackupPlansList[?starts_with(BackupPlanName, `tut-`)].{Name:BackupPlanName,Id:BackupPlanId,Created:CreationDate}' --output table

echo ""
echo "Tutorial complete."
echo "Note: No actual backup was started — the plan runs on a daily schedule."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws backup delete-backup-plan --backup-plan-id $PLAN_ID"
    echo "  aws backup delete-backup-vault --backup-vault-name $VAULT_NAME"
fi
