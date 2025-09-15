# Routing calls to AWS Lambda functions for Amazon Chime SDK PSTN audio

This tutorial guides you through the process of setting up call routing to AWS Lambda functions using Amazon Chime SDK PSTN audio service. You'll learn how to create Lambda functions, set up SIP media applications, and configure SIP rules to handle incoming calls.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with AWS Lambda and Amazon Chime SDK concepts.
4. [Sufficient permissions](https://docs.aws.amazon.com/chime-sdk/latest/dg/security_iam_service-with-iam.html) to create and manage Amazon Chime SDK and Lambda resources in your AWS account.
5. For the phone number-based routing, you need to have a phone number in your Amazon Chime SDK phone number inventory. Phone numbers cost $1.00 per number per month.
6. For the Voice Connector-based routing, you need to have a Voice Connector configured in your account.

### Cost considerations

This tutorial creates resources that are mostly free of charge:
- SIP Media Applications: $0.00 per application per month
- SIP Rules: $0.00 per rule per month
- Lambda functions: Covered by the AWS Free Tier for most users (1M free requests per month)

The main costs would come from:
- Phone numbers: $1.00 per phone number per month
- Call processing: Usage-based pricing that varies by call type and destination

For detailed pricing information including PSTN rates and PSTN Audio Application usage rates, see the [Amazon Chime SDK Pricing page](https://aws.amazon.com/chime/chime-sdk/pricing/).

The tutorial includes cleanup instructions to ensure you don't incur ongoing charges after completion.

Let's get started with setting up call routing for Amazon Chime SDK PSTN audio.

## Search for and provision phone numbers

Before creating SIP rules with phone number triggers, you need to have phone numbers in your Amazon Chime SDK inventory. Here's how to search for available phone numbers and provision them.

**Search for available phone numbers**

```bash
# Search for available toll-free phone numbers
aws chime-sdk-voice search-available-phone-numbers \
  --phone-number-type TollFree \
  --country US \
  --toll-free-prefix 844 \
  --max-results 5 \
  --region us-east-1
```

This command searches for available toll-free phone numbers with the prefix 844 in the US. You can modify the parameters to search for different types of numbers.

**Provision a phone number**

Once you've found an available phone number, you can provision it using the following command:

```bash
# Order a phone number
aws chime-sdk-voice create-phone-number-order \
  --product-type SipMediaApplicationDialIn \
  --e164-phone-numbers "+18443140123" \
  --region us-east-1
```

Replace `+18443140123` with an actual available phone number from your search results. This command will provision the phone number to your account, which costs $1.00 per month.

**Check phone number status**

After ordering a phone number, you can check its status:

```bash
# Get the phone number order status
aws chime-sdk-voice get-phone-number-order \
  --phone-number-order-id abcd1234-5678-90ab-cdef-EXAMPLE55555 \
  --region us-east-1
```

Replace the order ID with the one returned from the create-phone-number-order command.

**List phone numbers in your inventory**

To see all phone numbers in your inventory:

```bash
# List all phone numbers
aws chime-sdk-voice list-phone-numbers \
  --region us-east-1
```

To find unassigned phone numbers that can be used for SIP rules:

```bash
# List unassigned phone numbers
aws chime-sdk-voice list-phone-numbers \
  --region us-east-1 \
  --query "PhoneNumbers[?Status=='Unassigned'].E164PhoneNumber"
```

## Create a Lambda function for call handling

Now, let's create a Lambda function that will handle incoming calls. The function will receive events from the PSTN audio service and respond with instructions on how to handle the call.

**Create an IAM role for Lambda**

Before creating the Lambda function, you need to create an IAM role that grants the necessary permissions.

```bash
cat > lambda-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role --role-name ChimeSDKLambdaRole \
  --assume-role-policy-document file://lambda-trust-policy.json

aws iam attach-role-policy --role-name ChimeSDKLambdaRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

These commands create an IAM role that allows Lambda to assume it and attach the basic execution policy, which provides permissions for Lambda to write logs to CloudWatch.

**Create a Lambda function**

Now, create a simple Lambda function that will handle incoming calls.

```bash
mkdir -p lambda
cat > lambda/index.js << EOF
exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  // Simple call handling logic
  const response = {
    SchemaVersion: '1.0',
    Actions: [
      {
        Type: 'Speak',
        Parameters: {
          Engine: 'neural',
          Text: 'Hello! This is a test call from Amazon Chime SDK PSTN Audio.',
          VoiceId: 'Joanna'
        }
      },
      {
        Type: 'Hangup',
        Parameters: {
          SipResponseCode: '200'
        }
      }
    ]
  };

  return response;
};
EOF

cd lambda
zip -r function.zip index.js
cd ..

# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws lambda create-function \
  --function-name ChimeSDKCallHandler \
  --runtime nodejs18.x \
  --role arn:aws:iam::${ACCOUNT_ID}:role/ChimeSDKLambdaRole \
  --handler index.handler \
  --zip-file fileb://lambda/function.zip
```

This Lambda function responds to incoming calls with a spoken message and then hangs up.

**Add Lambda permission for Chime SDK**

Grant permission to the Amazon Chime SDK service to invoke your Lambda function.

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws lambda add-permission \
  --function-name ChimeSDKCallHandler \
  --statement-id ChimeSDK \
  --action lambda:InvokeFunction \
  --principal voiceconnector.chime.amazonaws.com \
  --source-account ${ACCOUNT_ID}
```

This command allows the Amazon Chime SDK Voice Connector service to invoke your Lambda function.

## Create a SIP media application

SIP media applications connect your Lambda function to the PSTN audio service. In this section, you'll create a SIP media application that uses your Lambda function.

**Create the SIP media application**

```bash
# Get your Lambda function ARN
LAMBDA_ARN=$(aws lambda get-function --function-name ChimeSDKCallHandler --query Configuration.FunctionArn --output text)

aws chime-sdk-voice create-sip-media-application \
  --aws-region us-east-1 \
  --name "MyCallHandlerApp" \
  --endpoints "[{\"LambdaArn\":\"${LAMBDA_ARN}\"}]"
```

The SIP media application acts as a bridge between the PSTN audio service and your Lambda function.

**Get the SIP media application ID**

After creating the SIP media application, you need to retrieve its ID for use in the next steps.

```bash
SIP_MEDIA_APP_ID=$(aws chime-sdk-voice list-sip-media-applications \
  --query "SipMediaApplications[?Name=='MyCallHandlerApp'].SipMediaApplicationId" \
  --output text)

echo "SIP Media Application ID: ${SIP_MEDIA_APP_ID}"
```

Make note of the SIP media application ID returned by this command, as you'll need it when creating SIP rules.

## Set up call routing with SIP rules

SIP rules determine how incoming calls are routed to your SIP media applications. You can create rules based on phone numbers or Voice Connector hostnames.

**Create a SIP rule with phone number trigger**

To route calls based on a phone number, use the following command:

```bash
# Get an unassigned phone number from your inventory
PHONE_NUMBER=$(aws chime-sdk-voice list-phone-numbers \
  --query "PhoneNumbers[?Status=='Unassigned'].E164PhoneNumber | [0]" \
  --output text)

# If no unassigned phone number is found, you'll need to provision one
if [ -z "$PHONE_NUMBER" ] || [ "$PHONE_NUMBER" == "None" ]; then
  echo "No unassigned phone numbers found. Please provision a phone number first."
  exit 1
fi

echo "Using phone number: ${PHONE_NUMBER}"

aws chime-sdk-voice create-sip-rule \
  --name "IncomingCallRule" \
  --trigger-type ToPhoneNumber \
  --trigger-value "${PHONE_NUMBER}" \
  --target-applications "[{\"SipMediaApplicationId\":\"${SIP_MEDIA_APP_ID}\",\"Priority\":1}]"
```

This command creates a SIP rule that routes calls to your phone number to your SIP media application.

**Create a SIP rule with Request URI hostname trigger**

Alternatively, you can route calls based on the request URI of an incoming Voice Connector SIP call:

```bash
# Replace with your Voice Connector hostname
VOICE_CONNECTOR_HOST="example.voiceconnector.chime.aws"

aws chime-sdk-voice create-sip-rule \
  --name "VoiceConnectorRule" \
  --trigger-type RequestUriHostname \
  --trigger-value "${VOICE_CONNECTOR_HOST}" \
  --target-applications "[{\"SipMediaApplicationId\":\"${SIP_MEDIA_APP_ID}\",\"Priority\":1}]"
```

Replace the hostname with your Voice Connector's outbound hostname.

## Set up redundancy with multiple SIP media applications

For redundancy and failover, you can create multiple SIP media applications in the same region and specify their order of priority.

**Create a backup Lambda function**

First, create a backup Lambda function in the same region.

```bash
cat > lambda/backup-index.js << EOF
exports.handler = async (event) => {
  console.log('Received event in backup handler:', JSON.stringify(event, null, 2));

  // Simple call handling logic for backup
  const response = {
    SchemaVersion: '1.0',
    Actions: [
      {
        Type: 'Speak',
        Parameters: {
          Engine: 'neural',
          Text: 'Hello! This is the backup handler for Amazon Chime SDK PSTN Audio.',
          VoiceId: 'Matthew'
        }
      },
      {
        Type: 'Hangup',
        Parameters: {
          SipResponseCode: '200'
        }
      }
    ]
  };

  return response;
};
EOF

cd lambda
zip -r backup-function.zip backup-index.js
cd ..

# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws lambda create-function \
  --function-name ChimeSDKBackupHandler \
  --runtime nodejs18.x \
  --role arn:aws:iam::${ACCOUNT_ID}:role/ChimeSDKLambdaRole \
  --handler backup-index.handler \
  --zip-file fileb://lambda/backup-function.zip
```

**Add Lambda permission for Chime SDK to the backup function**

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws lambda add-permission \
  --function-name ChimeSDKBackupHandler \
  --statement-id ChimeSDK \
  --action lambda:InvokeFunction \
  --principal voiceconnector.chime.amazonaws.com \
  --source-account ${ACCOUNT_ID}
```

**Create a backup SIP media application**

```bash
# Get your backup Lambda function ARN
BACKUP_LAMBDA_ARN=$(aws lambda get-function --function-name ChimeSDKBackupHandler --query Configuration.FunctionArn --output text)

aws chime-sdk-voice create-sip-media-application \
  --aws-region us-east-1 \
  --name "BackupCallHandlerApp" \
  --endpoints "[{\"LambdaArn\":\"${BACKUP_LAMBDA_ARN}\"}]"

# Get the backup SIP media application ID
BACKUP_SIP_MEDIA_APP_ID=$(aws chime-sdk-voice list-sip-media-applications \
  --query "SipMediaApplications[?Name=='BackupCallHandlerApp'].SipMediaApplicationId" \
  --output text)
```

**Get the SIP rule ID**

```bash
SIP_RULE_ID=$(aws chime-sdk-voice list-sip-rules \
  --query "SipRules[?Name=='IncomingCallRule'].SipRuleId" \
  --output text)
```

**Update SIP rule to include both applications with priorities**

```bash
aws chime-sdk-voice update-sip-rule \
  --sip-rule-id ${SIP_RULE_ID} \
  --target-applications "[{\"SipMediaApplicationId\":\"${SIP_MEDIA_APP_ID}\",\"Priority\":1},{\"SipMediaApplicationId\":\"${BACKUP_SIP_MEDIA_APP_ID}\",\"Priority\":2}]"
```

This command updates the SIP rule to include both the primary and backup SIP media applications with their respective priorities.

## Create outbound calls

You can also create outbound calls that invoke your Lambda function using the CreateSIPMediaApplicationCall API.

```bash
# Use a phone number from your inventory for outbound calling
FROM_PHONE_NUMBER=${PHONE_NUMBER}
TO_PHONE_NUMBER="+12065550102"  # Replace with a valid destination number

aws chime-sdk-voice create-sip-media-application-call \
  --from-phone-number "${FROM_PHONE_NUMBER}" \
  --to-phone-number "${TO_PHONE_NUMBER}" \
  --sip-media-application-id ${SIP_MEDIA_APP_ID}
```

Replace the destination phone number with a valid number. You need to have the phone numbers in your inventory to make real calls.

## Trigger Lambda during an active call

You can trigger your Lambda function during an active call using the UpdateSIPMediaApplicationCall API.

```bash
# Replace with an actual transaction ID from an active call
TRANSACTION_ID="txn-3ac9de3f-6b5a-4be9-9e7e-EXAMPLE33333"

aws chime-sdk-voice update-sip-media-application-call \
  --sip-media-application-id ${SIP_MEDIA_APP_ID} \
  --transaction-id ${TRANSACTION_ID} \
  --arguments '{"action":"custom-action"}'
```

The transaction ID is provided in the event data sent to your Lambda function when a call is active.

## Clean up resources

When you're finished with this tutorial, you should delete the resources you created to avoid incurring additional charges.

**Delete SIP rules**

```bash
# Get the SIP rule ID if you don't have it
SIP_RULE_ID=$(aws chime-sdk-voice list-sip-rules \
  --query "SipRules[?Name=='IncomingCallRule'].SipRuleId" \
  --output text)

aws chime-sdk-voice delete-sip-rule --sip-rule-id ${SIP_RULE_ID}
```

**Delete SIP media applications**

```bash
# Get SIP media application IDs if you don't have them
SIP_MEDIA_APP_ID=$(aws chime-sdk-voice list-sip-media-applications \
  --query "SipMediaApplications[?Name=='MyCallHandlerApp'].SipMediaApplicationId" \
  --output text)

BACKUP_SIP_MEDIA_APP_ID=$(aws chime-sdk-voice list-sip-media-applications \
  --query "SipMediaApplications[?Name=='BackupCallHandlerApp'].SipMediaApplicationId" \
  --output text)

aws chime-sdk-voice delete-sip-media-application --sip-media-application-id ${SIP_MEDIA_APP_ID}
aws chime-sdk-voice delete-sip-media-application --sip-media-application-id ${BACKUP_SIP_MEDIA_APP_ID}
```

**Delete Lambda functions**

```bash
aws lambda delete-function --function-name ChimeSDKCallHandler
aws lambda delete-function --function-name ChimeSDKBackupHandler
```

**Delete IAM role**

```bash
aws iam detach-role-policy --role-name ChimeSDKLambdaRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam delete-role --role-name ChimeSDKLambdaRole
```

**Release phone numbers**

If you no longer need the phone numbers, you can release them:

```bash
# List phone numbers
aws chime-sdk-voice list-phone-numbers

# Delete a specific phone number
aws chime-sdk-voice delete-phone-number --phone-number-id ${PHONE_NUMBER}
```

Note that phone numbers enter a "ReleaseInProgress" status for 7 days before being fully released. During this period, you can restore them using the `restore-phone-number` command if needed.

## Going to production

This tutorial demonstrates the basic functionality of routing calls to AWS Lambda functions using Amazon Chime SDK PSTN audio. However, for production environments, you should consider the following best practices:

### Security considerations

1. **Implement least privilege permissions**: Create custom IAM policies that grant only the specific permissions needed by your Lambda functions.

2. **Add source ARN conditions to Lambda permissions**: Restrict which SIP media applications can invoke your Lambda functions.

3. **Implement input validation**: Add validation to your Lambda functions to ensure they only process valid events.

4. **Consider VPC deployment**: For enhanced security, deploy your Lambda functions within a VPC with appropriate security groups.

5. **Encrypt sensitive data**: Use AWS KMS to encrypt any sensitive data used by your application.

### Architecture considerations

1. **Implement monitoring and logging**: Set up CloudWatch alarms and logs to monitor your application's health and performance.

2. **Add error handling**: Implement comprehensive error handling in your Lambda functions.

3. **Consider scaling limits**: Be aware of service quotas and request increases if needed for high call volumes.

4. **Implement infrastructure as code**: Use AWS CloudFormation or AWS CDK to deploy your infrastructure.

5. **Set up CI/CD pipelines**: Implement continuous integration and deployment for your Lambda functions.

For more information on building production-ready applications, refer to:

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/whitepapers/latest/aws-security-best-practices/aws-security-best-practices.html)
- [Serverless Applications Lens](https://docs.aws.amazon.com/wellarchitected/latest/serverless-applications-lens/welcome.html)

## Next steps

Now that you've learned how to route calls to AWS Lambda functions using Amazon Chime SDK PSTN audio, you can explore more advanced features:

1. [Build interactive voice response (IVR) systems](https://docs.aws.amazon.com/chime-sdk/latest/dg/build-lambdas-for-sip-sdk.html) with Amazon Chime SDK.
2. [Implement call recording](https://docs.aws.amazon.com/chime-sdk/latest/dg/call-analytics.html) for compliance and quality assurance.
3. [Integrate with Amazon Lex](https://docs.aws.amazon.com/chime-sdk/latest/dg/lex-bot-integration.html) for natural language understanding in your voice applications.
4. [Set up voice analytics](https://docs.aws.amazon.com/chime-sdk/latest/dg/pstn-analytics.html) to gain insights from your calls.
5. [Explore advanced call control actions](https://docs.aws.amazon.com/chime-sdk/latest/dg/pstn-audio-actions.html) to build sophisticated call flows.

## Security Considerations

This tutorial demonstrates basic AWS CLI usage for educational purposes. For production environments:
- Follow the [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- Implement least privilege access principles
- Enable appropriate logging and monitoring
- Review and apply security best practices specific to each service used

**Important:** This tutorial does not provide security guidance. Consult AWS security documentation and your security team for production deployments.