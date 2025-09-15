# Creating an Amazon Connect instance using the AWS CLI

Set up a cloud-based contact center with Amazon Connect

## Prerequisites

Before you begin this tutorial, you need:

- An AWS account with permissions to create Amazon Connect resources
- The AWS CLI installed and configured. For installation instructions, see [Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
- The `AmazonConnect_FullAccess` managed policy attached to your IAM user or role (for production environments, consider using more restrictive permissions)
- Basic familiarity with command line interfaces and JSON formatting
- Approximately 15-20 minutes to complete the tutorial

## Cost estimate

This tutorial creates resources that may incur charges to your AWS account:

- Amazon Connect phone number: $1.00 per month for a toll-free number in the US
- No charges for the Amazon Connect instance itself
- No charges for creating users or configuring the instance
- S3 storage for call recordings and chat transcripts: Standard S3 rates apply (approximately $0.023 per GB per month)
- KMS key usage for encryption: $1.00 per month per key plus $0.03 per 10,000 API requests

Total estimated cost: Less than $0.01 for completing the tutorial if you clean up resources afterward. If you keep the resources running, expect to pay approximately $1.00 per month for the phone number plus any applicable storage costs.

## Create an Amazon Connect instance

The first step is to create a new Amazon Connect instance. When creating an instance, you need to specify how you want to manage user identities.

**To create an Amazon Connect instance:**

```bash
aws connect create-instance \
  --identity-management-type CONNECT_MANAGED \
  --instance-alias my-contact-center \
  --inbound-calls-enabled \
  --outbound-calls-enabled
```

This command creates an instance with the following configuration:
- Identity management type: CONNECT_MANAGED (users stored in Amazon Connect)
- Instance alias: my-contact-center (this will be part of your access URL)
- Inbound and outbound calls enabled

The command returns the instance ID and ARN, which you'll need for subsequent commands:

```json
{
    "Id": "abcd1234-a123-4567-xmpl-a123b4cd56ef",
    "Arn": "arn:aws:connect:us-west-2:123456789012:instance/abcd1234-a123-4567-xmpl-a123b4cd56ef"
}
```

After creating the instance, you need to wait for it to become active before proceeding. This may take several minutes.

**To check the instance status:**

```bash
aws connect describe-instance \
  --instance-id abcd1234-a123-4567-xmpl-a123b4cd56ef
```

Wait until the `InstanceStatus` field shows `ACTIVE` before proceeding to the next step.

## Configure an administrator user

After your instance is active, you need to create an administrator user. First, you need to get the security profile ID for the Admin role and a routing profile ID.

**To list security profiles:**

```bash
aws connect list-security-profiles \
  --instance-id abcd1234-a123-4567-xmpl-a123b4cd56ef
```

Find the ID of the Admin security profile in the output:

```json
{
    "SecurityProfileSummaryList": [
        {
            "Id": "abcd1234-a123-4567-xmpl-a123b4cd56ef",
            "Arn": "arn:aws:connect:us-west-2:123456789012:instance/abcd1234-a123-4567-xmpl-a123b4cd56ef/security-profile/abcd1234-a123-4567-xmpl-a123b4cd56ef",
            "SecurityProfileName": "Admin"
        },
        ...
    ]
}
```

**To list routing profiles:**

```bash
aws connect list-routing-profiles \
  --instance-id abcd1234-a123-4567-xmpl-a123b4cd56ef
```

Note the ID of a routing profile from the output:

```json
{
    "RoutingProfileSummaryList": [
        {
            "Id": "abcd1234-a123-4567-xmpl-a123b4cd56ef",
            "Arn": "arn:aws:connect:us-west-2:123456789012:instance/abcd1234-a123-4567-xmpl-a123b4cd56ef/routing-profile/abcd1234-a123-4567-xmpl-a123b4cd56ef",
            "Name": "Basic Routing Profile"
        },
        ...
    ]
}
```

Now you can create an administrator user:

**To create an admin user:**

```bash
aws connect create-user \
  --instance-id abcd1234-a123-4567-xmpl-a123b4cd56ef \
  --username admin \
  --password "StrongPassword123!" \
  --identity-info FirstName=Admin,LastName=User,Email=admin@example.com \
  --phone-config PhoneType=DESK_PHONE,AutoAccept=true,AfterContactWorkTimeLimit=30,DeskPhoneNumber=+12065550100 \
  --security-profile-ids abcd1234-a123-4567-xmpl-a123b4cd56ef \
  --routing-profile-id abcd1234-a123-4567-xmpl-a123b4cd56ef
```

Make sure to replace the security profile ID and routing profile ID with the values you obtained from the previous commands. Also, use a strong, unique password instead of the example shown.

The command returns the user ID and ARN:

```json
{
    "UserId": "abcd1234-a123-4567-xmpl-a123b4cd56ef",
    "UserArn": "arn:aws:connect:us-west-2:123456789012:instance/abcd1234-a123-4567-xmpl-a123b4cd56ef/agent/abcd1234-a123-4567-xmpl-a123b4cd56ef"
}
```

## Configure telephony options

After creating your instance and administrator user, you can configure telephony options for your contact center.

**To enable early media audio:**

```bash
aws connect update-instance-attribute \
  --instance-id abcd1234-a123-4567-xmpl-a123b4cd56ef \
  --attribute-type EARLY_MEDIA \
  --value true
```

Early media allows your agents to hear pre-connection audio such as busy signals or failure-to-connect errors during outbound calls.

**To enable multi-party calls and enhanced monitoring for voice:**

```bash
aws connect update-instance-attribute \
  --instance-id abcd1234-a123-4567-xmpl-a123b4cd56ef \
  --attribute-type MULTI_PARTY_CONFERENCE \
  --value true
```

This enables up to six participants on a call.

**To enable multi-party chats and enhanced monitoring for chat:**

```bash
aws connect update-instance-attribute \
  --instance-id abcd1234-a123-4567-xmpl-a123b4cd56ef \
  --attribute-type MULTI_PARTY_CHAT_CONFERENCE \
  --value true
```

This enables up to six participants on a chat.

## View data storage configurations

Amazon Connect automatically creates storage configurations for various data types. You can view these configurations to understand where your data is stored.

**To list storage configurations for chat transcripts:**

```bash
aws connect list-instance-storage-configs \
  --instance-id abcd1234-a123-4567-xmpl-a123b4cd56ef \
  --resource-type CHAT_TRANSCRIPTS
```

The command returns information about the S3 bucket where chat transcripts are stored:

```json
{
    "StorageConfigs": [
        {
            "AssociationId": "abcd1234-a123-4567-xmpl-a123b4cd56ef",
            "StorageType": "S3",
            "S3Config": {
                "BucketName": "amzn-s3-demo-connect-abcd1234",
                "BucketPrefix": "connect/instance-id/chat-transcripts",
                "EncryptionConfig": {
                    "EncryptionType": "KMS",
                    "KeyId": "arn:aws:kms:us-west-2:123456789012:key/abcd1234-a123-4567-xmpl-a123b4cd56ef"
                }
            }
        }
    ]
}
```

You can also view storage configurations for other resource types by changing the `--resource-type` parameter to values like `CALL_RECORDINGS`, `SCHEDULED_REPORTS`, or `MEDIA_STREAMS`.

## Set up a phone number

To enable your contact center to receive calls, you need to set up a phone number.

**To search for available phone numbers:**

```bash
aws connect search-available-phone-numbers \
  --target-arn arn:aws:connect:us-west-2:123456789012:instance/abcd1234-a123-4567-xmpl-a123b4cd56ef \
  --phone-number-type TOLL_FREE \
  --phone-number-country-code US \
  --max-results 5
```

This command searches for available toll-free phone numbers in the United States. The output includes a list of available phone numbers:

```json
{
    "AvailableNumbersList": [
        {
            "PhoneNumber": "+18005550100",
            "PhoneNumberType": "TOLL_FREE",
            "PhoneNumberCountryCode": "US"
        },
        ...
    ]
}
```

**To claim a phone number:**

```bash
aws connect claim-phone-number \
  --target-arn arn:aws:connect:us-west-2:123456789012:instance/abcd1234-a123-4567-xmpl-a123b4cd56ef \
  --phone-number +18005550100
```

Replace the phone number with one from the search results. The command returns the claimed phone number's details:

```json
{
    "PhoneNumberId": "abcd1234-a123-4567-xmpl-a123b4cd56ef",
    "PhoneNumberArn": "arn:aws:connect:us-west-2:123456789012:phone-number/abcd1234-a123-4567-xmpl-a123b4cd56ef"
}
```

Make note of the `PhoneNumberId` value, as you'll need it to release the phone number later.

## Troubleshooting

**Instance creation fails with "ServiceQuotaExceededException"**

If you receive this error, you've reached the limit for the number of Amazon Connect instances in your account. You can request a quota increase through the Service Quotas console or delete unused instances.

**To check your current Amazon Connect instance quota:**

```bash
aws service-quotas get-service-quota \
  --service-code connect \
  --quota-code L-AA19FD77
```

**To list existing instances:**

```bash
aws connect list-instances
```

**Security profiles not found after instance creation**

If you can't list security profiles immediately after creating an instance, wait a few more minutes for the instance to fully initialize. The instance status may show as ACTIVE before all resources are fully provisioned.

**Phone number claim fails**

If claiming a phone number fails, the number may have been claimed by another user. Try searching for available numbers again and select a different one.

## Going to production

This tutorial demonstrates how to create and configure an Amazon Connect instance using the AWS CLI. For production environments, consider the following best practices:

### Security considerations

1. **Password management**: Store administrator passwords in AWS Secrets Manager instead of using hardcoded values or storing them in log files.

   ```bash
   aws secretsmanager create-secret \
     --name "connect/admin-password" \
     --secret-string "StrongPassword123!"
   ```

2. **IAM permissions**: Use the principle of least privilege by creating custom IAM policies instead of using the `AmazonConnect_FullAccess` managed policy.

3. **Resource tagging**: Apply tags to all resources for better organization, cost tracking, and access control.

   ```bash
   aws connect tag-resource \
     --resource-arn arn:aws:connect:us-west-2:123456789012:instance/abcd1234-a123-4567-xmpl-a123b4cd56ef \
     --tags Environment=Production,Owner=ContactCenterTeam
   ```

4. **Encryption**: Review and customize the default encryption settings for data storage.

5. **Network security**: Consider using Amazon Connect with AWS PrivateLink to keep traffic within the AWS network.

### Architecture best practices

1. **High availability**: Deploy Amazon Connect in multiple AWS regions for disaster recovery.

2. **Integration with identity providers**: For production environments, consider using SAML 2.0 identity providers instead of CONNECT_MANAGED user management.

3. **Monitoring and logging**: Set up CloudWatch alarms and dashboards to monitor your contact center performance.

4. **Contact flow versioning**: Use a version control system to manage your contact flow configurations.

For more information on production best practices, see:
- [Amazon Connect Security Best Practices](https://docs.aws.amazon.com/connect/latest/adminguide/security-best-practices.html)
- [Amazon Connect Architecture Center](https://aws.amazon.com/architecture/connect/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## Clean up resources

When you're done with your Amazon Connect instance, you can clean up the resources to avoid incurring charges.

**To release a claimed phone number:**

```bash
aws connect release-phone-number \
  --phone-number-id abcd1234-a123-4567-xmpl-a123b4cd56ef
```

**To delete the Amazon Connect instance:**

```bash
aws connect delete-instance \
  --instance-id abcd1234-a123-4567-xmpl-a123b4cd56ef
```

Deleting the instance will also delete all associated resources, including users, security profiles, and routing profiles.

## Next steps

Now that you've created an Amazon Connect instance, you can explore additional features:

- [Set up contact flows](https://docs.aws.amazon.com/connect/latest/adminguide/contact-flow.html) to define how contacts are handled in your contact center
- [Configure queues](https://docs.aws.amazon.com/connect/latest/adminguide/create-queue.html) to manage how contacts are distributed to agents
- [Set up quick connects](https://docs.aws.amazon.com/connect/latest/adminguide/quick-connects.html) to enable agents to transfer contacts to specific destinations
- [Enable contact recording](https://docs.aws.amazon.com/connect/latest/adminguide/set-up-recordings.html) to record customer interactions for quality assurance
- [Integrate with Amazon Lex](https://docs.aws.amazon.com/connect/latest/adminguide/amazon-lex.html) to add chatbots to your contact center
- [Set up real-time and historical metrics](https://docs.aws.amazon.com/connect/latest/adminguide/real-time-metrics-reports.html) to monitor your contact center performance
