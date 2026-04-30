# SQS: Create queues and send messages

## Source

https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-getting-started.html

## Use case

- **ID**: sqs/getting-started
- **Level**: beginner
- **Core actions**: `sqs:CreateQueue`, `sqs:SendMessage`

## Steps

1. Create a standard queue
2. Create a dead-letter queue and configure redrive policy
3. Send messages (individual and batch)
4. Receive and process messages
5. Delete processed messages
6. Check queue attributes
7. Create a FIFO queue and send a message

## Resources created

| Resource | Type |
|----------|------|
| `tut-queue-<random>` | Standard queue |
| `tut-dlq-<random>` | Dead-letter queue |
| `tut-fifo-<random>.fifo` | FIFO queue |

## Cost

Free tier includes 1 million requests/month. This tutorial sends fewer than 10 messages.

## Duration

~14 seconds

## Related docs

- [Getting started with Amazon SQS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-getting-started.html)
- [Amazon SQS dead-letter queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html)
- [Amazon SQS FIFO queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html)
- [Sending messages in batches](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-batch-api-actions.html)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 110 |
| Exit code | 0 |
| Runtime | 14s |
| Steps | 7 |
| Issues | Fixed f-string quoting |
| Version | v1 |
