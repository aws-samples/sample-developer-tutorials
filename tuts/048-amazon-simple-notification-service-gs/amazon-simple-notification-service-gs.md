# Create an Amazon SNS topic and publish messages using the AWS CLI

This tutorial guides you through the process of creating and managing Amazon Simple Notification Service (SNS) resources using the AWS Command Line Interface (CLI). You'll learn how to create a topic, subscribe to it, publish messages, and clean up resources.

## Prerequisites

Before you begin, make sure you have:

- An AWS account with appropriate permissions to create and manage SNS resources
- AWS CLI installed and configured with your credentials
- Basic familiarity with command-line operations

To install the AWS CLI, see [Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

To configure the AWS CLI, see [Configuration basics](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

### Cost information

The resources and operations used in this tutorial fall within the AWS Free Tier limits for Amazon SNS, which includes:
- 1 million Amazon SNS requests per month
- 100,000 HTTP/HTTPS notifications per month
- 1,000 email notifications per month

If you're not within the Free Tier period or exceed these limits, the costs are minimal for the operations in this tutorial. For current pricing information, see [Amazon SNS pricing](https://aws.amazon.com/sns/pricing/).

### Time to complete

This tutorial takes approximately 15-20 minutes to complete.

## Create an Amazon SNS topic

An Amazon SNS topic is a communication channel that allows you to send messages to multiple subscribers. In this step, you'll create a new SNS topic.

Run the following command to create a topic named "my-topic":

```bash
aws sns create-topic --name my-topic
```

The command returns the Amazon Resource Name (ARN) of your new topic, which you'll need for subsequent operations:

```json
{
    "TopicArn": "arn:aws:sns:us-west-2:123456789012:my-topic"
}
```

Make note of the TopicArn value as you'll need it for the following steps.

## Subscribe an email endpoint to the topic

Now that you have created a topic, you need to add subscribers who will receive the messages published to the topic. In this step, you'll subscribe an email address to receive notifications.

Run the following command to subscribe an email address to your topic. Replace `arn:aws:sns:us-west-2:123456789012:my-topic` with your actual topic ARN and `your-email@example.com` with your actual email address.

```bash
aws sns subscribe \
    --topic-arn arn:aws:sns:us-west-2:123456789012:my-topic \
    --protocol email \
    --notification-endpoint your-email@example.com
```



The command returns a response indicating that the subscription is pending confirmation:

```json
{
    "SubscriptionArn": "pending confirmation"
}
```

After running this command, you'll receive a confirmation email at the address you provided. You must click the "Confirm subscription" link in that email to activate your subscription.

## Verify your subscription

After confirming your subscription, you can verify that it was successful by listing all subscriptions for your topic.

Run the following command to list subscriptions. Replace `arn:aws:sns:us-west-2:123456789012:my-topic` with your actual topic ARN.

```bash
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-west-2:123456789012:my-topic
```

The command returns details about your subscription:

```json
{
    "Subscriptions": [
        {
            "SubscriptionArn": "arn:aws:sns:us-west-2:123456789012:my-topic:8a21d249-xmpl-4871-acc6-7be709c6ea7f",
            "Owner": "123456789012",
            "Protocol": "email",
            "Endpoint": "your-email@example.com",
            "TopicArn": "arn:aws:sns:us-west-2:123456789012:my-topic"
        }
    ]
}
```

Note that the `SubscriptionArn` is now a full ARN instead of "pending confirmation", which indicates that the subscription has been confirmed.
Make note of the SubscriptionArn value as you'll need it for the following steps.

## Publish a message to the topic

Now that you have a confirmed subscription, you can publish a message to the topic. When you publish a message, Amazon SNS delivers it to all confirmed subscribers.

Run the following command to publish a message:

```bash
aws sns publish \
    --topic-arn arn:aws:sns:us-west-2:123456789012:my-topic \
    --message 'Hello from Amazon SNS!'
```

Replace `arn:aws:sns:us-west-2:123456789012:my-topic` with your actual topic ARN.

The command returns a message ID, indicating that the message was successfully published:

```json
{
    "MessageId": "123a45b6-xmpl-12c3-45d6-111122223333"
}
```

After running this command, check your email inbox. You should receive the message you just published.

## Clean up resources

When you're done experimenting with Amazon SNS, you should clean up the resources you created to avoid incurring any unnecessary charges.

First, unsubscribe from the topic. Replace `arn:aws:sns:us-west-2:123456789012:my-topic:8a21d249-xmpl-4871-acc6-7be709c6ea7f` with your actual subscription ARN, which you can get from the output of the `list-subscriptions-by-topic` command.

```bash
aws sns unsubscribe --subscription-arn arn:aws:sns:us-west-2:123456789012:my-topic:8a21d249-xmpl-4871-acc6-7be709c6ea7f
```


Then, delete the topic. Replace `arn:aws:sns:us-west-2:123456789012:my-topic` with your actual topic ARN.

```bash
aws sns delete-topic --topic-arn arn:aws:sns:us-west-2:123456789012:my-topic
```

These commands don't produce any output if they're successful.

## Troubleshooting

### Subscription confirmation issues

**Issue 1**: You don't receive the confirmation email.

**Solution**:
- Check your spam or junk folder
- Verify that you entered the correct email address
- Try subscribing again with the same command

**Issue 2**: The subscription remains in "pending confirmation" state after clicking the confirmation link.

**Solution**:
- Wait a few minutes and run the `list-subscriptions-by-topic` command again
- Try clicking the confirmation link again
- Try subscribing again with a different email address

### Message publishing issues

**Issue**: You published a message but didn't receive it in your email.

**Solution**:
- Verify that your subscription is confirmed using the `list-subscriptions-by-topic` command
- Check your spam or junk folder
- Try publishing another message

## Going to production

This tutorial demonstrates basic Amazon SNS functionality for educational purposes. For production environments, consider these additional best practices:

### Security considerations

1. **Topic policies**: Implement least-privilege access by configuring topic policies:
   ```bash
   aws sns set-topic-attributes \
       --topic-arn your-topic-arn \
       --attribute-name Policy \
       --attribute-value '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::123456789012:role/YourRole"},"Action":"sns:Publish","Resource":"your-topic-arn"}]}'
   ```

2. **Server-side encryption**: Enable encryption for sensitive data:
   ```bash
   aws sns create-topic \
       --name my-secure-topic \
       --attributes '{"KmsMasterKeyId":"alias/aws/sns"}'
   ```

3. **Use HTTPS endpoints**: For sensitive information, use HTTPS endpoints instead of email.

### Architecture considerations

1. **Message filtering**: Implement subscription filter policies to deliver only relevant messages to subscribers.

2. **Dead-letter queues**: Configure dead-letter queues to capture failed message deliveries.

3. **Message archiving**: Consider using Amazon SNS FIFO topics for applications requiring strict message ordering.

For more information on building production-ready applications with Amazon SNS, see:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Security Best Practices for Amazon SNS](https://docs.aws.amazon.com/sns/latest/dg/sns-security-best-practices.html)
- [Amazon SNS Message Filtering](https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html)

## Next steps

Now that you've learned the basics of Amazon SNS, you can explore more advanced features:

- [Creating an Amazon SNS FIFO topic](https://docs.aws.amazon.com/sns/latest/dg/sns-fifo-topics.html) - Learn how to create and use FIFO (First-In-First-Out) topics for applications that require strict message ordering
- [Amazon SNS message filtering](https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html) - Discover how to filter messages so that subscribers receive only the messages they're interested in
- [Securing Amazon SNS data with server-side encryption](https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html) - Learn how to protect the contents of your messages using encryption
- [Amazon SNS dead-letter queues](https://docs.aws.amazon.com/sns/latest/dg/sns-dead-letter-queues.html) - Find out how to capture and analyze messages that couldn't be delivered to subscribers
