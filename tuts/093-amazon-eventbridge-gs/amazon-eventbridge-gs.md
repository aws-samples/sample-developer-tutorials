# Create an EventBridge rule that triggers a Lambda function on a schedule

This tutorial shows you how to create an Amazon EventBridge scheduled rule that invokes an AWS Lambda function every minute. You create the Lambda function, set up the rule, verify the function runs by checking CloudWatch Logs, and then clean up.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions to create EventBridge rules, Lambda functions, and IAM roles

## Step 1: Create an execution role

Create an IAM role that grants the Lambda function permission to write logs.

```bash
ROLE_ARN=$(aws iam create-role --role-name eb-tut-role \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }' --query 'Role.Arn' --output text)

aws iam attach-role-policy --role-name eb-tut-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

Wait about 10 seconds for the role to propagate before creating the function.

## Step 2: Create the Lambda function

Create a Node.js function that logs each EventBridge event it receives.

```javascript
// index.mjs
export const handler = async (event) => {
    console.log('EventBridge event received:', JSON.stringify(event, null, 2));
    return { statusCode: 200, body: 'Event processed' };
};
```

Package and deploy:

```bash
zip function.zip index.mjs

aws lambda create-function --function-name eb-tut-handler \
    --zip-file fileb://function.zip \
    --handler index.handler --runtime nodejs22.x \
    --role $ROLE_ARN --timeout 30 \
    --architectures x86_64
```

Wait for the function to become active:

```bash
aws lambda wait function-active-v2 --function-name eb-tut-handler
```

## Step 3: Create an EventBridge scheduled rule

Create a rule that fires every minute.

```bash
RULE_ARN=$(aws events put-rule --name eb-tut-rule \
    --schedule-expression "rate(1 minute)" \
    --state ENABLED \
    --query 'RuleArn' --output text)
```

## Step 4: Grant EventBridge permission to invoke Lambda

Add a resource-based policy that allows EventBridge to call the function.

```bash
aws lambda add-permission --function-name eb-tut-handler \
    --statement-id eb-invoke --action lambda:InvokeFunction \
    --principal events.amazonaws.com --source-arn $RULE_ARN
```

## Step 5: Add the Lambda function as a target

Attach the function to the rule so EventBridge invokes it on each trigger.

```bash
FUNCTION_ARN=$(aws lambda get-function --function-name eb-tut-handler \
    --query 'Configuration.FunctionArn' --output text)

aws events put-targets --rule eb-tut-rule \
    --targets "Id=lambda-target,Arn=$FUNCTION_ARN"
```

## Step 6: Verify in CloudWatch Logs

Wait about 60 seconds for the rule to fire, then check the function's log output:

```bash
aws logs describe-log-streams \
    --log-group-name /aws/lambda/eb-tut-handler \
    --order-by LastEventTime --descending --limit 1

aws logs get-log-events \
    --log-group-name /aws/lambda/eb-tut-handler \
    --log-stream-name <log-stream-name> \
    --query 'events[].message' --output text
```

You should see `EventBridge event received:` followed by the scheduled event JSON, which includes `"source": "aws.events"` and `"detail-type": "Scheduled Event"`.

## Cleanup

Delete all resources in reverse order:

```bash
aws events remove-targets --rule eb-tut-rule --ids lambda-target
aws events delete-rule --name eb-tut-rule
aws lambda delete-function --function-name eb-tut-handler
aws iam detach-role-policy --role-name eb-tut-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam delete-role --role-name eb-tut-role
aws logs delete-log-group --log-group-name /aws/lambda/eb-tut-handler
```

The script automates all steps including cleanup. Run it with:

```bash
bash amazon-eventbridge-gs.sh
```
