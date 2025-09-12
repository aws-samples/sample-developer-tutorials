# Getting started with AWS End User Messaging Push using the AWS CLI

This tutorial guides you through the process of setting up AWS End User Messaging Push and sending your first push notification using the AWS Command Line Interface (AWS CLI). AWS End User Messaging Push allows you to send push notifications to mobile applications through various push notification services including Firebase Cloud Messaging (FCM), Apple Push Notification service (APNs), Baidu Cloud Push, and Amazon Device Messaging (ADM).

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. **AWS CLI installed and configured**: The AWS CLI must be installed and configured with appropriate credentials. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

2. **AWS CLI validation**: You can verify your AWS CLI configuration by running:
   ```
   aws sts get-caller-identity
   ```
   This command should return your AWS account information without errors.

3. **Push notification credentials** from at least one of the supported services (FCM, APNs, Baidu, or ADM). For information on obtaining these credentials, see:
   - For APNs: [Establishing a Token-Based Connection to APNs](https://developer.apple.com/documentation/usernotifications/establishing-a-token-based-connection-to-apns)
   - For FCM: [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
   - For Baidu: [Baidu Cloud Push](https://push.baidu.com/)
   - For ADM: [Obtain Credentials](https://developer.amazon.com/docs/adm/obtain-credentials.html)

4. **IAM permissions**: [Sufficient permissions](https://docs.aws.amazon.com/push-notifications/latest/userguide/security_iam_service-with-iam.html) to create and manage AWS End User Messaging Push resources in your AWS account. At minimum, you need:
   - `mobiletargeting:CreateApp`
   - `mobiletargeting:DeleteApp`
   - `mobiletargeting:GetApp`
   - `mobiletargeting:UpdateGcmChannel`
   - `mobiletargeting:UpdateApnsChannel`
   - `mobiletargeting:SendMessages`

### Cost Information

The resources created in this tutorial fall within the AWS Free Tier:
- There is no charge for creating and maintaining an AWS End User Messaging Push application
- There is no charge for enabling push notification channels
- The first 1 million push notifications per month are free
- Beyond 1 million push notifications: $0.50 per million

For the most current pricing information, see [Amazon Pinpoint Pricing](https://aws.amazon.com/pinpoint/pricing/).

### Note on Service Naming

AWS End User Messaging Push uses the Amazon Pinpoint API and CLI commands. That's why the commands in this tutorial use the `pinpoint` namespace. AWS End User Messaging Push was previously part of Amazon Pinpoint before becoming a standalone service.

## Create an application

In AWS End User Messaging Push, an application serves as a container for all your push notification settings, channels, and configurations. Let's start by creating an application.

The following command creates a new application named "MyPushNotificationApp":

```
aws pinpoint create-app \
  --create-application-request Name="MyPushNotificationApp"
```

After running this command, you'll receive a response that includes the application ID, ARN, and other details. Take note of the application ID as you'll need it for subsequent commands.

```
{
    "ApplicationResponse": {
        "Arn": "arn:aws:mobiletargeting:us-west-2:123456789012:apps/abcd1234xmplabcd1234abcd1234",
        "Id": "abcd1234xmplabcd1234abcd1234",
        "Name": "MyPushNotificationApp",
        "tags": {},
        "CreationDate": "2025-01-13T12:00:00.000Z"
    }
}
```

The application ID is the unique identifier for your application. In this example, it's "abcd1234xmplabcd1234abcd1234". You'll use this ID in all subsequent commands to reference your application.

**Tip**: You can extract the application ID from the JSON response using tools like `jq`:
```
APP_ID=$(aws pinpoint create-app --create-application-request Name="MyPushNotificationApp" | jq -r '.ApplicationResponse.Id')
```

## Enable push notification channels

After creating your application, you need to enable one or more push notification channels based on the platforms you want to support. Each channel requires specific credentials from the respective push notification service.

**Important**: The following examples use placeholder credentials for demonstration purposes. In a production environment, you must replace these with your actual credentials from the respective services.

### Enable Firebase Cloud Messaging (FCM)

To enable the FCM channel for your application, you need an API key from your Firebase console. The following command enables the FCM channel:

```
aws pinpoint update-gcm-channel \
  --application-id abcd1234xmplabcd1234abcd1234 \
  --gcm-channel-request '{"Enabled": true, "ApiKey": "YOUR_FCM_API_KEY"}'
```

Replace `YOUR_FCM_API_KEY` with your actual FCM API key. If successful, you'll receive a response confirming that the channel has been enabled.

**Note:** Although Firebase Cloud Messaging (FCM) replaced Google Cloud Messaging (GCM) in 2018, the AWS CLI still uses "GCM" in its commands for backward compatibility. When you send push notifications through FCM, you'll use the service name `GCM` in your calls to the AWS End User Messaging Push API.

**Common errors**: If you receive an error like "FCM returned 404 UNREGISTERED", this typically means:
- The API key is invalid or placeholder
- The API key doesn't have the correct permissions in Firebase Console
- The Firebase project is not properly configured

### Enable Apple Push Notification service (APNs)

To enable the APNs channel, you can use either key credentials (recommended) or certificate credentials.

**Using key credentials:**

```
aws pinpoint update-apns-channel \
  --application-id abcd1234xmplabcd1234abcd1234 \
  --apns-channel-request '{
    "Enabled": true,
    "DefaultAuthenticationMethod": "KEY",
    "TokenKey": "YOUR_P8_FILE_CONTENT",
    "TokenKeyId": "YOUR_KEY_ID",
    "BundleId": "YOUR_BUNDLE_ID",
    "TeamId": "YOUR_TEAM_ID"
  }'
```

Replace the placeholder values with your actual APNs credentials from your Apple developer account.

**Using certificate credentials:**

```
aws pinpoint update-apns-channel \
  --application-id abcd1234xmplabcd1234abcd1234 \
  --apns-channel-request '{
    "Enabled": true,
    "DefaultAuthenticationMethod": "CERTIFICATE",
    "Certificate": "YOUR_BASE64_ENCODED_CERTIFICATE",
    "PrivateKey": "YOUR_PRIVATE_KEY",
    "CertificateType": "PRODUCTION"
  }'
```

Before using this command, you need to convert your .p12 certificate file to base64 format.

**Common errors**: If you receive an error like "The certificate provided is not a valid Apple certificate", this typically means:
- The certificate is a placeholder or invalid
- The certificate format is incorrect (should be PEM format)
- The private key doesn't match the certificate

### Enable Baidu Cloud Push

To enable the Baidu Cloud Push channel, use the following command:

```
aws pinpoint update-baidu-channel \
  --application-id abcd1234xmplabcd1234abcd1234 \
  --baidu-channel-request '{
    "Enabled": true,
    "ApiKey": "YOUR_BAIDU_API_KEY",
    "SecretKey": "YOUR_BAIDU_SECRET_KEY"
  }'
```

Replace the placeholder values with your actual Baidu credentials.

### Enable Amazon Device Messaging (ADM)

To enable the ADM channel, use the following command:

```
aws pinpoint update-adm-channel \
  --application-id abcd1234xmplabcd1234abcd1234 \
  --adm-channel-request '{
    "Enabled": true,
    "ClientId": "YOUR_ADM_CLIENT_ID",
    "ClientSecret": "YOUR_ADM_CLIENT_SECRET"
  }'
```

Replace the placeholder values with your actual ADM credentials.

## Send a push notification

After setting up your application and enabling the appropriate push notification channels, you can send push notifications to specific devices. The process varies slightly depending on which push notification service you're using.

**Important**: You need valid device tokens from actual devices to successfully send push notifications. The examples below use placeholder tokens for demonstration purposes.

### Send a push notification via FCM

First, create a JSON file named `gcm-message.json` with the following content:

```json
{
  "Addresses": {
    "DEVICE_TOKEN": {
      "ChannelType": "GCM"
    }
  },
  "MessageConfiguration": {
    "GCMMessage": {
      "Action": "OPEN_APP",
      "Body": "Hello from AWS End User Messaging Push!",
      "Priority": "normal",
      "SilentPush": false,
      "Title": "My First Push Notification",
      "TimeToLive": 30,
      "Data": {
        "key1": "value1",
        "key2": "value2"
      }
    }
  }
}
```

Replace `DEVICE_TOKEN` with the actual device token of the recipient's device. Note that for FCM, we use `GCM` as the channel type for backward compatibility.

Now, send the message using the following command:

```
aws pinpoint send-messages \
  --application-id abcd1234xmplabcd1234abcd1234 \
  --message-request file://gcm-message.json
```

If successful, you'll receive a response that includes the delivery status:

```json
{
  "MessageResponse": {
    "ApplicationId": "abcd1234xmplabcd1234abcd1234",
    "RequestId": "abcd1234-xmpl-abcd-1234-abcd1234abcd",
    "Result": {
      "DEVICE_TOKEN": {
        "DeliveryStatus": "SUCCESSFUL",
        "StatusCode": 200,
        "StatusMessage": "MessageId: abcd1234xmplabcd1234abcd1234"
      }
    }
  }
}
```

**Common errors**: If you receive an error like "GCM channel not found", this means:
- The FCM channel was not successfully enabled for your application
- You need to enable the FCM channel first using the `update-gcm-channel` command

### Send a push notification via APNs

To send a push notification to iOS devices, create a JSON file named `apns-message.json` with the following content:

```json
{
  "Addresses": {
    "DEVICE_TOKEN": {
      "ChannelType": "APNS"
    }
  },
  "MessageConfiguration": {
    "APNSMessage": {
      "Action": "OPEN_APP",
      "Body": "Hello from AWS End User Messaging Push!",
      "Priority": "normal",
      "SilentPush": false,
      "Title": "My First Push Notification",
      "TimeToLive": 30,
      "Badge": 1,
      "Sound": "default"
    }
  }
}
```

Replace `DEVICE_TOKEN` with the actual device token of the recipient's iOS device.

Send the message using the following command:

```
aws pinpoint send-messages \
  --application-id abcd1234xmplabcd1234abcd1234 \
  --message-request file://apns-message.json
```

**Common errors**: If you receive an error like "APNS channel not found", this means:
- The APNs channel was not successfully enabled for your application
- You need to enable the APNs channel first using the `update-apns-channel` command

## Troubleshooting

### Checking application details

You can retrieve information about your application and its configured channels using:

```
aws pinpoint get-app --application-id abcd1234xmplabcd1234abcd1234
```

### Checking channel status

To check if your channels are properly configured, you can use:

```
aws pinpoint get-gcm-channel --application-id abcd1234xmplabcd1234abcd1234
aws pinpoint get-apns-channel --application-id abcd1234xmplabcd1234abcd1234
```

### Common issues and solutions

1. **"Channel not found" errors**: Ensure you've successfully enabled the channel before attempting to send messages.

2. **Authentication errors**: Verify that your API keys, certificates, and other credentials are valid and properly formatted.

3. **Device token errors**: Ensure you're using valid, current device tokens from actual devices.

4. **Permission errors**: Verify that your AWS credentials have the necessary IAM permissions.

## Clean up resources

When you're done experimenting with AWS End User Messaging Push, you can delete the application to avoid incurring any charges.

The following command deletes the application:

```
aws pinpoint delete-app \
  --application-id abcd1234xmplabcd1234abcd1234
```

This command removes the application and all associated channels and configurations. Verify that the application has been deleted by listing all applications:

```
aws pinpoint get-apps
```

The deleted application should no longer appear in the list.

**Note**: Deleting the application also removes all associated channels, so you don't need to delete them individually.

## Going to production

This tutorial is designed to help you learn how AWS End User Messaging Push works, not to build a production-ready application. When moving to production, consider the following best practices:

### Security best practices

1. **Secure credential management**: Store API keys, certificates, and other credentials in AWS Secrets Manager or AWS Systems Manager Parameter Store instead of including them directly in commands.

2. **IAM permissions**: Create specific IAM roles with least privilege permissions for your production applications.

3. **Device token security**: Implement secure methods for storing and handling device tokens, which are sensitive identifiers.

4. **Environment separation**: Use separate applications for development, staging, and production environments.

### Architecture best practices

1. **Batch processing**: For large-scale applications, use batch operations to send notifications to multiple recipients efficiently.

2. **Segmentation**: Implement user segmentation to target specific groups of users.

3. **Message templates**: Use templates to maintain consistent messaging across your application.

4. **Monitoring and analytics**: Set up CloudWatch metrics and alarms to monitor your push notification service.

5. **Error handling**: Implement robust error handling and retry logic for failed notifications.

6. **Rate limiting**: Be aware of rate limits for different push notification services and implement appropriate throttling.

### Automation and scripting

Consider creating scripts to automate common tasks:

1. **Application setup**: Automate the creation of applications and channel configuration.
2. **Credential rotation**: Implement automated credential rotation for security.
3. **Monitoring**: Set up automated monitoring and alerting for your push notification service.

For more information on building production-ready applications with AWS, see:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [AWS Messaging and Targeting Best Practices](https://docs.aws.amazon.com/pinpoint/latest/userguide/best-practices.html)

## Next steps

Now that you've learned how to set up AWS End User Messaging Push and send basic push notifications, you can explore more advanced features:

- [Create and use push notification templates](https://docs.aws.amazon.com/pinpoint/latest/userguide/message-templates-creating-push.html) to standardize your messaging
- [Send messages to specific segments](https://docs.aws.amazon.com/pinpoint/latest/userguide/segments.html) of your user base
- [Schedule campaigns](https://docs.aws.amazon.com/pinpoint/latest/userguide/campaigns.html) to send push notifications at specific times
- [Analyze push notification metrics](https://docs.aws.amazon.com/pinpoint/latest/userguide/analytics.html) to understand engagement
- [Implement rich push notifications](https://docs.aws.amazon.com/pinpoint/latest/userguide/channels-mobile-manage.html) with images and interactive elements
