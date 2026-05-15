# AWS Firehose Tutorial: Creating and Testing a Delivery Stream

This tutorial guides you through creating an AWS Firehose delivery stream, waiting for it to become active, and putting a record into it. You'll learn how to transport data to an S3 bucket using AWS Firehose.

## Topics

- [Prerequisites](#prerequisites)
- [Creating a delivery stream](#creating-a-delivery-stream)
- [Waiting for the stream to become active](#waiting-for-the-stream-to-become-active)
- [Putting a record into the stream](#putting-a-record-into-the-stream)
- [Clean up resources](#clean-up-resources)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces.
4. Sufficient permissions to create and manage AWS Firehose delivery streams.

## Creating a delivery stream

**Creating a delivery stream**

We are creating an AWS Firehose delivery stream to transport data to an S3 bucket. The delivery stream is named uniquely to avoid conflicts and is configured to use DirectPut for simplicity.

```bash
$ STREAM="test-stream-xmpl"
$ ROLE_ARN="arn:aws:iam::123456789012:role/doc-babu-firehose-role"
$ aws firehose create-delivery-stream \
  --delivery-stream-name "$STREAM" \
  --delivery-stream-type DirectPut \
  --extended-s3-destination-configuration "RoleARN=$ROLE_ARN,BucketARN=arn:aws:s3:::doc-babu-test-bucket,Prefix=firehose-xmpl/"
```

Result: Delivery stream created with name `test-stream-xmpl`

## Waiting for the stream to become active

**Waiting for the stream to become active**

After creating the delivery stream, we need to wait for it to become active before we can use it. This step ensures that the stream is ready to accept data.

```bash
$ for i in $(seq 1 12); do
  STATUS=$(aws firehose describe-delivery-stream --delivery-stream-name "$STREAM" --query 'DeliveryStreamDescription.DeliveryStreamStatus' --output text)
  if [ "$STATUS" = "ACTIVE" ]; then break; fi
  sleep 5
done
```

Result: Status of the delivery stream is `ACTIVE`

## Putting a record into the stream

**Putting a record into the stream**

Now that the delivery stream is active, we can put a record into it. This demonstrates how to send data to the stream, which will then be delivered to the configured S3 bucket.

```bash
$ aws firehose put-record --delivery-stream-name "$STREAM" --record '{"Data":"aGVsbG8gZmlyZWhvc2UK"}'
```

Result: Record successfully put into the delivery stream

## Clean up resources

To avoid unnecessary charges, clean up the resources you created. The script automatically deletes the delivery stream when it exits.

## Next steps

- Learn more about [AWS Firehose features](https://docs.aws.amazon.com/firehose/latest/dev/what-is-this-service.html).
- Explore [AWS Firehose best practices](https://docs.aws.amazon.com/firehose/latest/dev/best-practices.html).
- Discover how to [monitor AWS Firehose with CloudWatch](https://docs.aws.amazon.com/firehose/latest/dev/monitoring-cloudwatch.html).