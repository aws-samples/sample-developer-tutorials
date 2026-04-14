# Budgets: Create a cost budget

## Source

https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-create.html

## Use case

- **ID**: budgets/getting-started
- **Level**: beginner
- **Core actions**: `budgets:CreateBudget`, `budgets:DescribeBudget`, `budgets:DescribeBudgets`

## Steps

1. Create a monthly cost budget ($100 limit)
2. Describe the budget
3. Check current spend vs budget
4. List all budgets

## Resources created

| Resource | Type |
|----------|------|
| `tutorial-budget-<random>` | Budget |

## Cost

Free. The first two budgets per account have no charge. Additional budgets cost $0.02/day each.

## Duration

~5 seconds

## Related docs

- [Creating a cost budget](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-create.html)
- [Managing your costs with AWS Budgets](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- [AWS Budgets CLI reference](https://docs.aws.amazon.com/cli/latest/reference/budgets/index.html)

---

## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 |
| Source script | New, 76 lines |
| Script test result | EXIT 0, 5s, 4 steps, no issues |
| Issues encountered | None |
| Iterations | v1 (direct to publish) |
