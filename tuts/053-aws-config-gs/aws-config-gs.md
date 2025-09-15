# Getting started with AWS Config using the AWS CLI

This tutorial guides you through setting up AWS Config using the AWS Command Line Interface (AWS CLI). AWS Config provides a detailed view of the resources in your AWS account and their configurations, allowing you to assess, audit, and evaluate the configurations of your AWS resources.

## Topics

- [Prerequisites](#prerequisites)
- [Create an Amazon S3 bucket](#create-an-amazon-s3-bucket)
- [Create an Amazon SNS topic](#create-an-amazon-sns-topic)
- [Create an IAM role for AWS Config](#create-an-iam-role-for-aws-config)
- [Set up the AWS Config configuration recorder](#set-up-the-aws-config-configuration-recorder)
- [Set up the AWS Config delivery channel](#set-up-the-aws-config-delivery-channel)
- [Start the configuration recorder](#start-the-configuration-recorder)
- [Verify the AWS Config setup](#verify-the-aws-config-setup)
- [Going to production](#going-to-production)
- [Clean up resources](#clean-up-resources)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. [Sufficient permissions](https://docs.aws.amazon.com/config/latest/developerguide/security-iam.html) to create and manage AWS Config resources in your AWS account.

### Cost considerations

This tutorial creates several AWS resources that incur charges to your AWS account:

- **AWS Config**: Approximately $0.30 per hour for recording configuration items in a typical account with around 100 resources.
- **Amazon S3**: Minimal storage costs for configuration items (less than $0.01 per hour).
- **Amazon SNS**: Minimal messaging costs for configuration notifications (less than $0.01 per hour).

The total estimated cost is approximately $0.31 per hour. Make sure to follow the cleanup steps at the end of the tutorial to avoid ongoing charges. AWS Free Tier benefits may apply for new AWS accounts.

## Create an Amazon S3 bucket

AWS Config delivers configuration snapshots and history files to an S3 bucket. In this step, you'll create a bucket specifically for AWS Config data.

**Create an S3 bucket**

The following command creates an S3 bucket with a unique name. The command varies slightly depending on your AWS Region.

```bash
# For us-east-1 region
aws s3api create-bucket \
    --bucket amzn-s3-demo-bucket-config

# For other regions (example: us-west-2)
aws s3api create-bucket \
    --bucket amzn-s3-demo-bucket-config \
    --create-bucket-configuration LocationConstraint=us-west-2
```

After running this command, you'll see output similar to the following:

```json
{
    "Location": "/amzn-s3-demo-bucket-config"
}
```

**Block public access to the bucket**

As a security best practice, block all public access to the bucket:

```bash
aws s3api put-public-access-block \
    --bucket amzn-s3-demo-bucket-config \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

This command doesn't produce any output when successful, but it ensures that your AWS Config data remains private.

**Enable server-side encryption for the bucket**

To protect your configuration data, enable default encryption for the bucket:

```bash
aws s3api put-bucket-encryption \
    --bucket amzn-s3-demo-bucket-config \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'
```

This command enables AES-256 encryption for all objects stored in the bucket.

## Create an Amazon SNS topic

AWS Config can send notifications about configuration changes through an Amazon SNS topic. In this step, you'll create a topic for these notifications.

**Create an SNS topic**

The following command creates an SNS topic for AWS Config notifications:

```bash
aws sns create-topic --name config-topic
```

The command returns the Amazon Resource Name (ARN) of the new topic:

```json
{
    "TopicArn": "arn:aws:sns:us-west-2:123456789012:config-topic"
}
```

Make note of this ARN as you'll need it in later steps.

**Enable server-side encryption for the SNS topic**

To protect the notification data, enable server-side encryption for the SNS topic:

```bash
aws sns set-topic-attributes \
    --topic-arn arn:aws:sns:us-west-2:123456789012:config-topic \
    --attribute-name KmsMasterKeyId \
    --attribute-value alias/aws/sns
```

This command enables encryption using the default AWS managed key for SNS.

## Create an IAM role for AWS Config

AWS Config needs permissions to access your resources and deliver configuration information to your S3 bucket and SNS topic. In this step, you'll create an IAM role with the necessary permissions.

**Create a trust policy document**

First, create a trust policy document that allows AWS Config to assume the role:

```bash
cat > config-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "123456789012"
        }
      }
    }
  ]
}
EOF
```

Replace `123456789012` with your AWS account ID. The condition ensures that only AWS Config in your account can assume this role.

**Create the IAM role**

Now create the IAM role using the trust policy:

```bash
aws iam create-role \
    --role-name config-role \
    --assume-role-policy-document file://config-trust-policy.json
```

The command returns information about the new role:

```json
{
    "Role": {
        "Path": "/",
        "RoleName": "config-role",
        "RoleId": "AROAABCD1234EXAMPLE",
        "Arn": "arn:aws:iam::123456789012:role/config-role",
        "CreateDate": "2025-01-13T00:00:00Z",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "config.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole",
                    "Condition": {
                        "StringEquals": {
                            "aws:SourceAccount": "123456789012"
                        }
                    }
                }
            ]
        }
    }
}
```

Make note of the role ARN as you'll need it in later steps.

**Attach the AWS managed policy for AWS Config**

Attach the AWS managed policy that grants AWS Config the permissions it needs:

```bash
aws iam attach-role-policy \
    --role-name config-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWS_ConfigRole
```

**Create a custom policy for S3 and SNS access**

Create a policy document that grants permissions to write to your S3 bucket and publish to your SNS topic:

```bash
cat > config-delivery-permissions.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::amzn-s3-demo-bucket-config/AWSLogs/123456789012/*",
      "Condition": {
        "StringLike": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketAcl"
      ],
      "Resource": "arn:aws:s3:::amzn-s3-demo-bucket-config"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "arn:aws:sns:us-west-2:123456789012:config-topic",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:config:us-west-2:123456789012:*"
        }
      }
    }
  ]
}
EOF
```

Replace the account ID (`123456789012`) with your actual AWS account ID and update the SNS topic ARN with the one you created earlier. The condition in the SNS permission ensures that only AWS Config can publish to the topic.

**Attach the custom policy to the role**

```bash
aws iam put-role-policy \
    --role-name config-role \
    --policy-name config-delivery-permissions \
    --policy-document file://config-delivery-permissions.json
```

**Add tags to the IAM role**

Add tags to the role for better resource management:

```bash
aws iam tag-role \
    --role-name config-role \
    --tags '[{"Key":"Purpose","Value":"AWSConfig"},{"Key":"Environment","Value":"Tutorial"}]'
```

## Set up the AWS Config configuration recorder

The configuration recorder is responsible for detecting changes to your resource configurations. In this step, you'll create and configure the recorder.

**Create configuration recorder configuration**

Create a JSON file that defines your configuration recorder:

```bash
cat > configurationRecorder.json << EOF
{
  "name": "default",
  "roleARN": "arn:aws:iam::123456789012:role/config-role",
  "recordingMode": {
    "recordingFrequency": "CONTINUOUS"
  }
}
EOF
```

Replace the role ARN with the ARN of the role you created earlier.

**Create recording group configuration**

Create a JSON file that defines which resources to record:

```bash
cat > recordingGroup.json << EOF
{
  "allSupported": true,
  "includeGlobalResourceTypes": true
}
EOF
```

This configuration tells AWS Config to record all supported resource types, including global resources.

**Create the configuration recorder**

Now create the configuration recorder using the files you just created:

```bash
aws configservice put-configuration-recorder \
    --configuration-recorder file://configurationRecorder.json \
    --recording-group file://recordingGroup.json
```

This command doesn't produce any output when successful.

## Set up the AWS Config delivery channel

The delivery channel defines where AWS Config sends configuration information. In this step, you'll set up a delivery channel that sends data to your S3 bucket and notifications to your SNS topic.

**Create delivery channel configuration**

Create a JSON file that defines your delivery channel:

```bash
cat > deliveryChannel.json << EOF
{
  "name": "default",
  "s3BucketName": "amzn-s3-demo-bucket-config",
  "snsTopicARN": "arn:aws:sns:us-west-2:123456789012:config-topic",
  "configSnapshotDeliveryProperties": {
    "deliveryFrequency": "Six_Hours"
  }
}
EOF
```

Replace the S3 bucket name and SNS topic ARN with the ones you created earlier.

**Create the delivery channel**

Now create the delivery channel using the file you just created:

```bash
aws configservice put-delivery-channel \
    --delivery-channel file://deliveryChannel.json
```

This command doesn't produce any output when successful.

## Start the configuration recorder

After setting up the configuration recorder and delivery channel, you need to start the recorder to begin tracking resource configurations.

**Start the configuration recorder**

```bash
aws configservice start-configuration-recorder \
    --configuration-recorder-name default
```

This command doesn't produce any output when successful. Once started, AWS Config will begin recording the configuration of resources in your account.

## Verify the AWS Config setup

After completing the setup, you should verify that AWS Config is running correctly.

**Verify the delivery channel**

Check that your delivery channel is properly configured:

```bash
aws configservice describe-delivery-channels
```

You should see output similar to the following:

```json
{
    "DeliveryChannels": [
        {
            "name": "default",
            "s3BucketName": "amzn-s3-demo-bucket-config",
            "snsTopicARN": "arn:aws:sns:us-west-2:123456789012:config-topic",
            "configSnapshotDeliveryProperties": {
                "deliveryFrequency": "Six_Hours"
            }
        }
    ]
}
```

**Verify the configuration recorder**

Check that your configuration recorder is properly configured:

```bash
aws configservice describe-configuration-recorders
```

You should see output similar to the following:

```json
{
    "ConfigurationRecorders": [
        {
            "name": "default",
            "roleARN": "arn:aws:iam::123456789012:role/config-role",
            "recordingGroup": {
                "allSupported": true,
                "includeGlobalResourceTypes": true,
                "resourceTypes": []
            }
        }
    ]
}
```

**Verify the configuration recorder status**

Check that your configuration recorder is running:

```bash
aws configservice describe-configuration-recorder-status
```

You should see output similar to the following:

```json
{
    "ConfigurationRecordersStatus": [
        {
            "name": "default",
            "lastStartTime": "2025-01-13T00:00:00.000Z",
            "recording": true,
            "lastStatus": "SUCCESS",
            "lastStatusChangeTime": "2025-01-13T00:00:00.000Z"
        }
    ]
}
```

The `"recording": true` field confirms that the configuration recorder is running.

## Going to production

This tutorial demonstrates how to set up AWS Config for learning purposes. For production environments, consider the following best practices:

### Security considerations

1. **Encryption**: Enable encryption for all resources, including S3 buckets and SNS topics. This tutorial includes steps for this, but in production, consider using customer-managed KMS keys.

2. **IAM permissions**: Use more restrictive IAM policies with conditions that limit access based on source IP, VPC endpoints, or other contextual information.

3. **Monitoring**: Set up CloudWatch alarms to monitor AWS Config operational metrics and detect issues.

4. **Security Hub integration**: Integrate AWS Config with AWS Security Hub for comprehensive security posture management.

### Architecture considerations

1. **Multi-account strategy**: For enterprise environments, use AWS Config Aggregators and AWS Organizations integration to manage configuration across multiple accounts.

2. **Resource selection**: In large environments, be selective about which resource types to record based on compliance needs, rather than recording all supported types.

3. **Data lifecycle**: Implement S3 lifecycle policies to archive or delete older configuration items to manage storage costs.

4. **Regional strategy**: Consider setting up AWS Config in multiple regions for global visibility and disaster recovery.

For more information on production best practices, see:
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/whitepapers/latest/aws-security-best-practices/welcome.html)
- [AWS Config Best Practices](https://docs.aws.amazon.com/config/latest/developerguide/operational-best-practices.html)

## Clean up resources

When you're finished with this tutorial, you should clean up the resources you created to avoid incurring additional charges.

**Stop the configuration recorder**

Before deleting resources, stop the configuration recorder:

```bash
aws configservice stop-configuration-recorder \
    --configuration-recorder-name default
```

**Delete the delivery channel**

```bash
aws configservice delete-delivery-channel \
    --delivery-channel-name default
```

**Delete the configuration recorder**

```bash
aws configservice delete-configuration-recorder \
    --configuration-recorder-name default
```

**Delete the IAM role and policies**

```bash
aws iam delete-role-policy \
    --role-name config-role \
    --policy-name config-delivery-permissions

aws iam detach-role-policy \
    --role-name config-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWS_ConfigRole

aws iam delete-role \
    --role-name config-role
```

**Delete the SNS topic**

```bash
aws sns delete-topic \
    --topic-arn arn:aws:sns:us-west-2:123456789012:config-topic
```

**Empty and delete the S3 bucket**

```bash
aws s3 rm s3://amzn-s3-demo-bucket-config --recursive
aws s3api delete-bucket --bucket amzn-s3-demo-bucket-config
```

## Next steps

Now that you've set up AWS Config, you can explore its features:

1. [Create AWS Config rules](https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html) to evaluate resource configurations.
2. [View configuration history and changes](https://docs.aws.amazon.com/config/latest/developerguide/view-manage-resource.html) for your resources.
3. [Set up AWS Config conformance packs](https://docs.aws.amazon.com/config/latest/developerguide/conformance-packs.html) to deploy governance rules and remediation actions.
4. [Use AWS Config with AWS Organizations](https://docs.aws.amazon.com/config/latest/developerguide/config-concepts.html#multi-account-multi-region-aggregation) for multi-account, multi-region data aggregation.
5. [Integrate AWS Config with other AWS services](https://docs.aws.amazon.com/config/latest/developerguide/config-concepts.html#integration-with-other-services) like AWS Security Hub and AWS CloudTrail.
