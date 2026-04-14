# Using Lambda with Amazon SQS

This tutorial shows you how to create a Lambda function that processes messages from an Amazon SQS queue. You create the function, test it with a sample event, connect it to an SQS queue, and verify end-to-end message processing.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions to create Lambda functions, IAM roles, and SQS queues

## Step 1: Create an execution role

Create an IAM role with the `AWSLambdaSQSQueueExecutionRole` managed policy, which grants permissions to read from SQS and write logs.

```bash
aws iam create-role --role-name lambda-sqs-role \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }'

aws iam attach-role-policy --role-name lambda-sqs-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
```

Wait about 10 seconds for the role to propagate.

## Step 2: Create the Lambda function

Create a Node.js function that logs each SQS message body.

```javascript
// index.mjs
export const handler = async (event) => {
    for (const message of event.Records) {
        console.log(`Processed message: ${message.body}`);
    }
    return { statusCode: 200 };
};
```

Package and deploy:

```bash
zip function.zip index.mjs

aws lambda create-function --function-name sqs-processor \
    --zip-file fileb://function.zip \
    --handler index.handler --runtime nodejs22.x \
    --role arn:aws:iam::<account-id>:role/lambda-sqs-role \
    --architectures x86_64
```

Wait for the function to become active:

```bash
aws lambda wait function-active-v2 --function-name sqs-processor
```

## Step 3: Test with a sample event

Invoke the function with a sample SQS event to verify it works:

```bash
aws lambda invoke --function-name sqs-processor \
    --payload fileb://test-event.json \
    --cli-binary-format raw-in-base64-out response.json
```

## Step 4: Create an SQS queue

```bash
aws sqs create-queue --queue-name lambda-test-queue
QUEUE_URL=$(aws sqs get-queue-url --queue-name lambda-test-queue --query 'QueueUrl' --output text)
QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url $QUEUE_URL \
    --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)
```

## Step 5: Create an event source mapping

Connect the SQS queue to the Lambda function:

```bash
aws lambda create-event-source-mapping \
    --function-name sqs-processor \
    --batch-size 10 \
    --event-source-arn $QUEUE_ARN
```

## Step 6: Send test messages

```bash
aws sqs send-message --queue-url $QUEUE_URL --message-body "Hello from the Lambda-SQS tutorial"
aws sqs send-message --queue-url $QUEUE_URL --message-body "This is message number 2"
```

## Step 7: Verify in CloudWatch Logs

After about 15 seconds, check the function's log output:

```bash
aws logs describe-log-streams --log-group-name /aws/lambda/sqs-processor \
    --order-by LastEventTime --descending --limit 1

aws logs get-log-events --log-group-name /aws/lambda/sqs-processor \
    --log-stream-name <log-stream-name> \
    --query 'events[].message' --output text
```

You should see `Processed message: Hello from the Lambda-SQS tutorial` in the output.

## Cleanup

```bash
aws lambda delete-event-source-mapping --uuid <mapping-uuid>
aws lambda delete-function --function-name sqs-processor
aws sqs delete-queue --queue-url $QUEUE_URL
aws iam detach-role-policy --role-name lambda-sqs-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
aws iam delete-role --role-name lambda-sqs-role
```

The script automates all steps including cleanup. Run it with:

```bash
bash lambda-sqs.sh
```
