#!/bin/bash
# Tutorial: Create a cost budget with AWS Budgets
# Source: https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-create.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/budgets-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Region: $REGION"
echo "Account: $ACCOUNT_ID"

RANDOM_ID=$(openssl rand -hex 4)
BUDGET_NAME="tutorial-budget-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws budgets delete-budget --account-id "$ACCOUNT_ID" --budget-name "$BUDGET_NAME" 2>/dev/null && \
        echo "  Deleted budget $BUDGET_NAME"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a monthly cost budget
echo "Step 1: Creating monthly cost budget: $BUDGET_NAME (\$100 limit)"
cat > "$WORK_DIR/budget.json" << EOF
{
    "BudgetName": "$BUDGET_NAME",
    "BudgetLimit": {"Amount": "100", "Unit": "USD"},
    "BudgetType": "COST",
    "TimeUnit": "MONTHLY",
    "TimePeriod": {
        "Start": "2026-04-01T00:00:00Z",
        "End": "2087-06-15T00:00:00Z"
    }
}
EOF
aws budgets create-budget --account-id "$ACCOUNT_ID" \
    --budget "file://$WORK_DIR/budget.json"
echo "  Budget created"

# Step 2: Describe the budget
echo "Step 2: Describing the budget"
aws budgets describe-budget --account-id "$ACCOUNT_ID" --budget-name "$BUDGET_NAME" \
    --query 'Budget.{Name:BudgetName,Limit:BudgetLimit.Amount,Type:BudgetType,TimeUnit:TimeUnit}' --output table

# Step 3: Check current spend vs budget
echo "Step 3: Current spend vs budget"
aws budgets describe-budget --account-id "$ACCOUNT_ID" --budget-name "$BUDGET_NAME" \
    --query 'Budget.CalculatedSpend.{ActualSpend:ActualSpend.Amount,ForecastedSpend:ForecastedSpend.Amount}' --output table

# Step 4: List all budgets
echo "Step 4: Listing all budgets"
aws budgets describe-budgets --account-id "$ACCOUNT_ID" \
    --query 'Budgets[].{Name:BudgetName,Limit:BudgetLimit.Amount,Type:BudgetType}' --output table

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws budgets delete-budget --account-id $ACCOUNT_ID --budget-name $BUDGET_NAME"
fi
