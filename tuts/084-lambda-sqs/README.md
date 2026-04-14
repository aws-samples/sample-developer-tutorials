# Lambda: Process SQS messages

Create a Lambda function that processes messages from an Amazon SQS queue, with event source mapping for automatic invocation.

## Source

https://docs.aws.amazon.com/lambda/latest/dg/with-sqs-example.html

## Use case

- ID: lambda/sqs-trigger
- Phase: create
- Complexity: beginner
- Core actions: lambda:CreateFunction, lambda:CreateEventSourceMapping, sqs:SendMessage

## What it does

1. Creates an IAM execution role with SQS permissions
2. Creates a Node.js Lambda function that logs message bodies
3. Tests the function with a sample SQS event
4. Creates an SQS queue
5. Creates an event source mapping (queue → function)
6. Sends test messages to the queue
7. Verifies processing via CloudWatch Logs
8. Cleans up all resources

## Running

```bash
bash lambda-sqs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash lambda-sqs.sh
```

## Resources created

- IAM role (with AWSLambdaSQSQueueExecutionRole policy)
- Lambda function (Node.js 22)
- SQS queue
- Event source mapping
- CloudWatch log group (created automatically by Lambda)

## Estimated time

- Run: ~45 seconds
- Cleanup: ~10 seconds

## Cost

Free tier eligible. No charges expected for a few messages.

## Related docs

- [Using Lambda with Amazon SQS](https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html)
- [Tutorial: Using Lambda with Amazon SQS](https://docs.aws.amazon.com/lambda/latest/dg/with-sqs-example.html)
- [Amazon SQS visibility timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html)

---

## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 |
| Source script | Rewritten from internal 084-lambda-sqs-2-cli-script-v2.sh |
| Script test result | EXIT 0, 44s, 7 steps, clean teardown |
| Issues encountered | Original used `set -e` with `log_command` wrapper (replaced with ERR trap); missing `fileb://` for payload (fixed); original used nodejs22.x (kept) |
| Iterations | v1 (internal), v2 (wait-for-active + region fix), v3 (clean rewrite for publish) |
