# Using an AWS Lambda function as a subscriber to an Amazon SNS topic

This tutorial shows you how to create a Lambda function that processes messages published to an Amazon SNS topic. You create the topic, subscribe a Lambda function to it, publish a test message, and verify the function processed it.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions to create Lambda functions, IAM roles, and SNS topics

## Step 1: Create an SNS topic

Create a topic that your Lambda function will subscribe to.

```bash
TOPIC_ARN=$(aws sns create-topic --name my-sns-topic --query 'TopicArn' --output text)
```

## Step 2: Create an execution role

Create an IAM role that grants the Lambda function permission to write logs.

```bash
aws iam create-role --role-name lambda-sns-role \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }'

aws iam attach-role-policy --role-name lambda-sns-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

Wait about 10 seconds for the role to propagate.

## Step 3: Create the Lambda function

Create a Node.js function that logs each SNS message it receives.

```javascript
// index.mjs
export const handler = async (event) => {
    for (const record of event.Records) {
        console.log(`Processed message: ${record.Sns.Message}`);
    }
    return { statusCode: 200 };
};
```

Package and deploy:

```bash
zip function.zip index.mjs

aws lambda create-function --function-name sns-processor \
    --zip-file fileb://function.zip \
    --handler index.handler --runtime nodejs22.x \
    --role arn:aws:iam::<account-id>:role/lambda-sns-role \
    --architectures x86_64
```

Wait for the function to become active:

```bash
aws lambda wait function-active-v2 --function-name sns-processor
```

## Step 4: Subscribe the function to the topic

Grant SNS permission to invoke the function, then create the subscription.

```bash
aws lambda add-permission --function-name sns-processor \
    --statement-id sns-invoke --action lambda:InvokeFunction \
    --principal sns.amazonaws.com --source-arn $TOPIC_ARN

aws sns subscribe --protocol lambda \
    --topic-arn $TOPIC_ARN \
    --notification-endpoint $(aws lambda get-function --function-name sns-processor \
        --query 'Configuration.FunctionArn' --output text)
```

## Step 5: Publish a test message

```bash
aws sns publish --topic-arn $TOPIC_ARN \
    --message "Hello from the Lambda-SNS tutorial" --subject "Test"
```

## Step 6: Verify in CloudWatch Logs

After a few seconds, check the function's log output:

```bash
aws logs describe-log-streams --log-group-name /aws/lambda/sns-processor \
    --order-by LastEventTime --descending --limit 1

aws logs get-log-events --log-group-name /aws/lambda/sns-processor \
    --log-stream-name <log-stream-name> \
    --query 'events[].message' --output text
```

You should see `Processed message: Hello from the Lambda-SNS tutorial` in the output.

## Cleanup

Delete all resources in reverse order:

```bash
aws sns unsubscribe --subscription-arn <subscription-arn>
aws lambda delete-function --function-name sns-processor
aws iam detach-role-policy --role-name lambda-sns-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam delete-role --role-name lambda-sns-role
aws sns delete-topic --topic-arn $TOPIC_ARN
```

The script automates all steps including cleanup. Run it with:

```bash
bash lambda-sns.sh
```
