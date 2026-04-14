# Lambda: Process SNS messages

Create a Lambda function that subscribes to an SNS topic, processes published messages, and logs the results.

## Source

https://docs.aws.amazon.com/lambda/latest/dg/with-sns-example.html

## Use case

- ID: lambda/sns-trigger
- Phase: create
- Complexity: beginner
- Core actions: lambda:CreateFunction, sns:Subscribe, sns:Publish

## What it does

1. Creates an SNS topic
2. Creates an IAM execution role for Lambda
3. Creates a Node.js Lambda function that logs SNS messages
4. Subscribes the function to the topic
5. Publishes a test message
6. Verifies the function processed it via CloudWatch Logs
7. Cleans up all resources

## Running

```bash
bash lambda-sns.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash lambda-sns.sh
```

## Resources created

- SNS topic
- IAM role (with AWSLambdaBasicExecutionRole policy)
- Lambda function (Node.js 22)
- SNS subscription
- CloudWatch log group (created automatically by Lambda)

## Estimated time

- Run: ~30 seconds
- Cleanup: ~5 seconds

## Cost

Free tier eligible. No charges expected for a single message.

## Related docs

- [Using Lambda with Amazon SNS](https://docs.aws.amazon.com/lambda/latest/dg/with-sns.html)
- [Tutorial: Using an AWS Lambda function as a subscriber](https://docs.aws.amazon.com/lambda/latest/dg/with-sns-example.html)
- [Amazon SNS message filtering](https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html)

---

## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 |
| Source script | Rewritten from internal 089-lambda-sns-2-cli-script-v3.sh |
| Script test result | EXIT 0, 33s, 6 steps, clean teardown |
| Issues encountered | ERR trap recursion in log retrieval loop (fixed with `|| true`); `add-permission` JSON output noise (suppressed); original used nodejs18.x (upgraded to 22) |
| Iterations | v1 (internal, nodejs18), v2 (wait-for-active patch), v3 (clean rewrite for publish) |
