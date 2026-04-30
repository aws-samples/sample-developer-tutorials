# Create a cost budget with AWS Budgets

This tutorial shows you how to create a monthly cost budget with a $100 limit, inspect the budget details and current spend, list all budgets in your account, and delete the budget.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions for `budgets:CreateBudget`, `budgets:DescribeBudget`, `budgets:DescribeBudgets`, `budgets:DeleteBudget`

## Step 1: Create a monthly cost budget

Create a JSON budget definition and pass it to `create-budget`. The budget tracks actual spend against a $100 monthly limit.

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
BUDGET_NAME="tutorial-budget-$(openssl rand -hex 4)"

cat > /tmp/budget.json << EOF
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
    --budget "file:///tmp/budget.json"
```

`BudgetType` can be `COST`, `USAGE`, `RI_UTILIZATION`, `RI_COVERAGE`, `SAVINGS_PLANS_UTILIZATION`, or `SAVINGS_PLANS_COVERAGE`. This tutorial uses `COST` to track dollar spend.

## Step 2: Describe the budget

```bash
aws budgets describe-budget --account-id "$ACCOUNT_ID" \
    --budget-name "$BUDGET_NAME" \
    --query 'Budget.{Name:BudgetName,Limit:BudgetLimit.Amount,Type:BudgetType,TimeUnit:TimeUnit}' \
    --output table
```

## Step 3: Check current spend vs budget

```bash
aws budgets describe-budget --account-id "$ACCOUNT_ID" \
    --budget-name "$BUDGET_NAME" \
    --query 'Budget.CalculatedSpend.{ActualSpend:ActualSpend.Amount,ForecastedSpend:ForecastedSpend.Amount}' \
    --output table
```

`CalculatedSpend` shows actual spend so far in the current period and the forecasted spend by period end. A new budget shows zero for both values.

## Step 4: List all budgets

```bash
aws budgets describe-budgets --account-id "$ACCOUNT_ID" \
    --query 'Budgets[].{Name:BudgetName,Limit:BudgetLimit.Amount,Type:BudgetType}' \
    --output table
```

## Cleanup

Delete the budget:

```bash
aws budgets delete-budget --account-id "$ACCOUNT_ID" \
    --budget-name "$BUDGET_NAME"
```

The first two budgets per account are free. Deleting the budget removes it immediately. The script automates all steps including cleanup:

```bash
bash aws-budgets-gs.sh
```

## Related resources

- [Creating a cost budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-create.html)
- [Managing your costs with AWS Budgets](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- [AWS Budgets CLI reference](https://docs.aws.amazon.com/cli/latest/reference/budgets/index.html)
