# Create an Amazon SNS email contact

This tutorial guides you through creating, listing, and deleting an Amazon Simple Notification Service (SNS) email contact using the AWS CLI.

## Prerequisites

- Install and configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
- Ensure you have the necessary permissions to create and delete SNS topics.

## Steps

**1. Create email contact**

```bash
$ TOPIC_ARN=$(aws sns create-topic --name "$NAME" --attributes '{"DisplayName":"'"$EMAIL_ADDRESS"'"}' --query 'TopicArn' --output text)
```

This command creates an SNS topic with a unique name and display name matching the generated email address.

**2. Tag the resource**

```bash
$ aws sns tag-resource --resource-arn "$TOPIC_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=notificationscontacts-gs
```

Apply tags to the created SNS topic for easier management and identification.

**3. List topics**

```bash
$ aws sns list-topics --query 'Topics' --output json
```

Retrieve a list of all SNS topics in your account to verify the creation of the new topic.

**4. Delete email contact**

```bash
$ aws sns delete-topic --topic-arn "$TOPIC_ARN" || true
```

Remove the SNS topic to clean up resources.

## Clean up

The script automatically cleans up created resources by deleting the SNS topic and removing temporary files.

## Next steps

- Explore [Amazon SNS documentation](https://docs.aws.amazon.com/sns/latest/dg/welcome.html) for more features and use cases.
- Learn how to [subscribe to an SNS topic](https://docs.aws.amazon.com/sns/latest/dg/sns-tutorials.html) to receive notifications.
