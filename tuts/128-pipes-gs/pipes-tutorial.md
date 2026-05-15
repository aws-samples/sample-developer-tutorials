# Tutorial: Setting Up AWS EventBridge Pipes

## Prerequisites

- Ensure you have the AWS CLI installed and configured with the necessary permissions.
- Basic understanding of AWS services, particularly SQS and CloudWatch Logs.

## Steps

### 1. Create an SQS Queue

**Command:**

```bash
$ aws sqs create-queue --tags '{"project":"doc-smith","tutorial":"pipes-gs"}' --queue-name "pipe-queue-$SUFFIX" --query 'QueueUrl' --output text
```

**Guidance:**

This command creates an SQS queue with a unique name and tags for project and tutorial identification. The output is the queue URL, which is stored for later use.

### 2. Create a CloudWatch Log Group

**Commands:**

```bash
$ aws logs create-log-group --log-group-name "/aws/pipes/pipe-$SUFFIX"
$ aws logs tag-resource --resource-arn "arn:aws:logs:us-east-1:123456789012:log-group:/aws/pipes/pipe-$SUFFIX" --tags '{"project":"doc-smith","tutorial":"pipes-gs"}'
```

**Guidance:**

These commands create a CloudWatch Log Group with a unique name and apply tags for project and tutorial identification. The resource ARN is used to tag the log group.

### 3. List Existing Pipes

**Command:**

```bash
$ aws pipes list-pipes --query 'Pipes[].Name' --output text || echo "No pipes"
```

**Guidance:**

This command lists the names of existing pipes. If no pipes exist, it outputs "No pipes".

## Clean Up

All created resources are automatically cleaned up at the end of the tutorial to avoid unnecessary charges. This includes deleting the SQS queue and the CloudWatch Log Group.

## Next Steps

- Explore creating an EventBridge Pipe using the SQS queue and CloudWatch Log Group created in this tutorial.
- Review the [AWS EventBridge Pipes documentation](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-pipes.html) for more advanced configurations and use cases.