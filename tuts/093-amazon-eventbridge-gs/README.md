# EventBridge: Schedule a Lambda function

Create an EventBridge scheduled rule that invokes a Lambda function every minute, verify execution in CloudWatch Logs, and clean up.

## Source

https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-get-started.html

## Use case

- ID: eventbridge/getting-started
- Phase: create
- Complexity: beginner
- Core actions: events:PutRule, events:PutTargets

## What it does

1. Creates an IAM execution role for Lambda
2. Creates a Node.js Lambda function that logs EventBridge events
3. Creates an EventBridge rule with a `rate(1 minute)` schedule
4. Grants EventBridge permission to invoke the function
5. Adds the Lambda function as the rule target
6. Waits for the rule to fire and verifies output in CloudWatch Logs

## Running

```bash
bash amazon-eventbridge-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash amazon-eventbridge-gs.sh
```

## Resources created

- EventBridge rule (scheduled, rate 1 minute)
- Lambda function (Node.js 22)
- IAM role (with AWSLambdaBasicExecutionRole policy)
- CloudWatch log group (created automatically by Lambda)

## Estimated time

- Run: ~90 seconds (includes 65s wait for rule to fire)
- Cleanup: ~5 seconds

## Cost

Free tier eligible. Lambda and EventBridge invocations stay well within free tier limits for this tutorial.

## Related docs

- [Getting started with Amazon EventBridge](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-get-started.html)
- [Creating a rule that runs on a schedule](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html)
- [Tutorial: Use EventBridge to relay events to a Lambda function](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-log-ec2-instance-state.html)
- [Schedule expressions using rate or cron](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-scheduled-rule-pattern.html)

---

## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 |
| Script lines | 130 |
| Script test result | EXIT 0, 91s, 6 steps, clean teardown |
| Issues encountered | None |
| Iterations | v1 direct to publish |
