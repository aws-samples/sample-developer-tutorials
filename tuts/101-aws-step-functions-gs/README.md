# Step Functions: Create and run a state machine

## Source

https://docs.aws.amazon.com/step-functions/latest/dg/getting-started-with-sfn.html

## Use case

- **ID**: stepfunctions/getting-started
- **Level**: intermediate
- **Core actions**: `states:CreateStateMachine`, `states:StartExecution`

## Steps

1. Create an IAM role for Step Functions
2. Create a state machine (Pass → Wait → Choice → Succeed)
3. Start an execution
4. Wait for execution to complete
5. Get execution results
6. Get execution history

## Resources created

| Resource | Type |
|----------|------|
| State machine | `AWS::StepFunctions::StateMachine` |
| IAM role | `AWS::IAM::Role` |

## Duration

~22 seconds

## Cost

Step Functions free tier includes 4,000 state transitions per month. This tutorial uses approximately 5 transitions per execution. All resources are removed during cleanup.

## Related docs

- [Getting started with Step Functions](https://docs.aws.amazon.com/step-functions/latest/dg/getting-started-with-sfn.html)
- [Amazon States Language](https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html)
- [Step Functions API reference](https://docs.aws.amazon.com/step-functions/latest/apireference/Welcome.html)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 133 |
| Exit code | 0 |
| Runtime | 22s |
| Steps | 6 |
| Issues | None |
| Version | v1 |
