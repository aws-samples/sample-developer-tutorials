# Create queues and send messages with Amazon SQS

## Overview

In this tutorial, you use the AWS CLI to create a standard queue, a dead-letter queue, and a FIFO queue. You send individual and batch messages, receive and delete them, and inspect queue attributes. You then clean up all queues.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- An IAM principal with permissions for `sqs:CreateQueue`, `sqs:DeleteQueue`, `sqs:SendMessage`, `sqs:SendMessageBatch`, `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:GetQueueAttributes`, and `sqs:SetQueueAttributes`.

## Step 1: Create a standard queue

Create a queue with a 30-second visibility timeout and 1-day message retention.

```bash
RANDOM_ID=$(openssl rand -hex 4)
QUEUE_NAME="tut-queue-${RANDOM_ID}"

QUEUE_URL=$(aws sqs create-queue --queue-name "$QUEUE_NAME" \
    --attributes '{"VisibilityTimeout":"30","MessageRetentionPeriod":"86400"}' \
    --query 'QueueUrl' --output text)
echo "Queue URL: $QUEUE_URL"
```

The visibility timeout controls how long a message stays hidden after a consumer receives it. If the consumer doesn't delete the message within that window, it becomes visible again.

## Step 2: Create a dead-letter queue

Create a second queue to capture messages that fail processing, then attach it to the main queue with a redrive policy.

```bash
DLQ_NAME="tut-dlq-${RANDOM_ID}"

DLQ_URL=$(aws sqs create-queue --queue-name "$DLQ_NAME" --query 'QueueUrl' --output text)
DLQ_ARN=$(aws sqs get-queue-attributes --queue-url "$DLQ_URL" \
    --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

aws sqs set-queue-attributes --queue-url "$QUEUE_URL" \
    --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"}"
```

After a message is received 3 times without being deleted, SQS moves it to the dead-letter queue.

## Step 3: Send messages

Send two individual messages and a batch of three.

```bash
aws sqs send-message --queue-url "$QUEUE_URL" \
    --message-body "Hello from SQS tutorial"

aws sqs send-message --queue-url "$QUEUE_URL" \
    --message-body "Message with attributes" \
    --message-attributes '{"Author":{"DataType":"String","StringValue":"Tutorial"}}'

aws sqs send-message-batch --queue-url "$QUEUE_URL" --entries \
    '[{"Id":"m1","MessageBody":"Batch message 1"},{"Id":"m2","MessageBody":"Batch message 2"},{"Id":"m3","MessageBody":"Batch message 3"}]'
```

`send-message-batch` accepts up to 10 messages per call. Each entry needs a unique `Id` within the batch.

## Step 4: Receive and process messages

Receive up to 5 messages, including any message attributes.

```bash
MSGS=$(aws sqs receive-message --queue-url "$QUEUE_URL" \
    --max-number-of-messages 5 \
    --message-attribute-names All --attribute-names All)
echo "$MSGS" | python3 -c "
import sys, json
msgs = json.load(sys.stdin).get('Messages', [])
for m in msgs:
    print(f'Body: {m[\"Body\"]}')
print(f'Received {len(msgs)} messages')
"
```

Messages remain in the queue until explicitly deleted. If you don't delete them within the visibility timeout, they become available to other consumers.

## Step 5: Delete processed messages

Delete each received message using its receipt handle.

```bash
echo "$MSGS" | python3 -c "
import sys, json, subprocess
msgs = json.load(sys.stdin).get('Messages', [])
for m in msgs:
    subprocess.run(['aws', 'sqs', 'delete-message',
        '--queue-url', '$QUEUE_URL',
        '--receipt-handle', m['ReceiptHandle']], capture_output=True)
print(f'Deleted {len(msgs)} messages')
"
```

## Step 6: Check queue attributes

View the queue's current configuration including message counts and redrive policy.

```bash
aws sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names All \
    --query 'Attributes.{Messages:ApproximateNumberOfMessages,Visibility:VisibilityTimeout,Retention:MessageRetentionPeriod,DLQ:RedrivePolicy}' \
    --output table
```

## Step 7: Create a FIFO queue

Create a FIFO queue with content-based deduplication and send a message.

```bash
FIFO_NAME="tut-fifo-${RANDOM_ID}.fifo"

FIFO_URL=$(aws sqs create-queue --queue-name "$FIFO_NAME" \
    --attributes '{"FifoQueue":"true","ContentBasedDeduplication":"true"}' \
    --query 'QueueUrl' --output text)

aws sqs send-message --queue-url "$FIFO_URL" \
    --message-body "FIFO message" --message-group-id "tutorial"
```

FIFO queues guarantee exactly-once processing and strict ordering within each message group. The queue name must end with `.fifo`.

## Cleanup

Delete all three queues.

```bash
aws sqs delete-queue --queue-url "$QUEUE_URL"
aws sqs delete-queue --queue-url "$DLQ_URL"
aws sqs delete-queue --queue-url "$FIFO_URL"
```

After deletion, the queue name becomes available again after 60 seconds.

The script automates all steps including cleanup:

```bash
bash amazon-sqs-gs.sh
```

## Related resources

- [Getting started with Amazon SQS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-getting-started.html)
- [Amazon SQS dead-letter queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html)
- [Amazon SQS FIFO queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html)
- [Sending messages in batches](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-batch-api-actions.html)
