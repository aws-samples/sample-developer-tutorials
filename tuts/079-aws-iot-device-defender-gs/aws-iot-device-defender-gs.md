# Getting Started with AWS IoT Device Defender Using the AWS CLI

AWS IoT Device Defender is a security service that helps you secure your fleet of IoT devices. It allows you to audit the configuration of your devices, monitor connected devices to detect abnormal behavior, and mitigate security risks. This tutorial guides you through setting up AWS IoT Device Defender using the AWS Command Line Interface (CLI).

## Prerequisites

Before you begin, make sure you have:

1. An AWS account with appropriate permissions
2. AWS CLI installed and configured with your credentials
3. Basic knowledge of AWS IoT and security concepts

## Pricing Considerations

This tutorial uses several AWS services that may incur costs in your AWS account:

- **AWS IoT Device Defender**: Pricing is based on the number of devices in your fleet and the features you use:
  - Audit pricing: Per device count per month (devices connected to AWS IoT)
  - Detect pricing: Per device per month for rules-based anomaly detection
  - ML Detect pricing: Per device per month for machine learning-based anomaly detection

- **Amazon CloudWatch Logs**: Costs are based on the amount of log data ingested and stored
  - Data ingestion: Per GB
  - Data storage: Per GB per month
  - Log retention settings affect storage costs

- **Amazon SNS**: Costs are based on the number of notifications sent
  - First 1 million Amazon SNS requests per month are free
  - Standard SNS publish requests: Per million requests
  - Email/Email-JSON deliveries: Per 100,000 notifications

For the most up-to-date pricing information, refer to:
- [AWS IoT Device Defender Pricing](https://aws.amazon.com/iot-device-defender/pricing/)
- [Amazon CloudWatch Pricing](https://aws.amazon.com/cloudwatch/pricing/)
- [Amazon SNS Pricing](https://aws.amazon.com/sns/pricing/)

## Step 1: Create Required IAM Roles

AWS IoT Device Defender requires several IAM roles to function properly. We'll create three roles:
- An audit role for performing security audits
- A logging role for sending logs to CloudWatch
- A mitigation action role for executing remediation actions

```bash
# Create IoT Device Defender Audit role
aws iam create-role \
  --role-name AWSIoTDeviceDefenderAuditRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "iot.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

# Attach the AWSIoTDeviceDefenderAudit policy to the role
aws iam attach-role-policy \
  --role-name AWSIoTDeviceDefenderAuditRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSIoTDeviceDefenderAudit

# Store the role ARN for later use
AUDIT_ROLE_ARN=$(aws iam get-role --role-name AWSIoTDeviceDefenderAuditRole --query 'Role.Arn' --output text)
echo "Audit Role ARN: $AUDIT_ROLE_ARN"

# Create IoT Logging role
aws iam create-role \
  --role-name AWSIoTLoggingRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "iot.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

# Create an inline policy for the logging role
aws iam put-role-policy \
  --role-name AWSIoTLoggingRole \
  --policy-name AWSIoTLoggingRolePolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:PutRetentionPolicy",
          "logs:GetLogEvents",
          "logs:DescribeLogStreams"
        ],
        "Resource": [
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  }'

# Store the logging role ARN for later use
LOGGING_ROLE_ARN=$(aws iam get-role --role-name AWSIoTLoggingRole --query 'Role.Arn' --output text)
echo "Logging Role ARN: $LOGGING_ROLE_ARN"

# Create IoT Mitigation Action role
aws iam create-role \
  --role-name IoTMitigationActionErrorLoggingRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "iot.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

# Create an inline policy for the mitigation action role
aws iam put-role-policy \
  --role-name IoTMitigationActionErrorLoggingRole \
  --policy-name IoTMitigationActionErrorLoggingRolePolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "iot:UpdateCACertificate",
          "iot:UpdateCertificate",
          "iot:SetV2LoggingOptions",
          "iot:SetLoggingOptions",
          "iot:AddThingToThingGroup",
          "iot:PublishToTopic",
          "iam:PassRole"
        ],
        "Resource": "*"
      }
    ]
  }'

# Store the mitigation role ARN for later use
MITIGATION_ROLE_ARN=$(aws iam get-role --role-name IoTMitigationActionErrorLoggingRole --query 'Role.Arn' --output text)
echo "Mitigation Role ARN: $MITIGATION_ROLE_ARN"
```

## Step 2: Enable AWS IoT Device Defender Audit Checks

Now that we have the necessary roles, let's enable the audit checks. AWS IoT Device Defender provides several audit checks to verify that your IoT configuration follows security best practices. In this tutorial, we'll enable the `LOGGING_DISABLED_CHECK` which verifies that AWS IoT logging is enabled.

```bash
# Get the current audit configuration
aws iot describe-account-audit-configuration

# Enable the LOGGING_DISABLED_CHECK audit check
aws iot update-account-audit-configuration \
  --role-arn "$AUDIT_ROLE_ARN" \
  --audit-check-configurations '{"LOGGING_DISABLED_CHECK":{"enabled":true}}'

# Verify the updated configuration
aws iot describe-account-audit-configuration
```

AWS IoT Device Defender offers several other audit checks that you can enable, including:

- `DEVICE_CERTIFICATE_EXPIRING_CHECK`: Checks for expiring device certificates
- `CA_CERTIFICATE_EXPIRING_CHECK`: Checks for expiring CA certificates
- `CONFLICTING_CLIENT_IDS_CHECK`: Checks for devices using the same client ID
- `IOT_POLICY_OVERLY_PERMISSIVE_CHECK`: Checks for overly permissive IoT policies
- `REVOKED_DEVICE_CERTIFICATE_STILL_ACTIVE_CHECK`: Checks for revoked but still active certificates

You can enable these checks by adding them to the `audit-check-configurations` parameter.

## Step 3: Run an On-Demand Audit

Let's run an on-demand audit to check for compliance issues:

```bash
# Start an on-demand audit task
AUDIT_TASK_RESULT=$(aws iot start-on-demand-audit-task \
  --target-check-names LOGGING_DISABLED_CHECK)

# Extract the task ID
TASK_ID=$(echo "$AUDIT_TASK_RESULT" | grep -o '"taskId": "[^"]*' | cut -d'"' -f4)
echo "Audit task started with ID: $TASK_ID"

# Wait for the audit task to complete
echo "Waiting for audit task to complete (this may take a few minutes)..."
TASK_STATUS="IN_PROGRESS"
while [ "$TASK_STATUS" != "COMPLETED" ]; do
  sleep 10
  TASK_DETAILS=$(aws iot describe-audit-task --task-id "$TASK_ID")
  TASK_STATUS=$(echo "$TASK_DETAILS" | grep -o '"taskStatus": "[^"]*' | cut -d'"' -f4)
  echo "Current task status: $TASK_STATUS"

  # Exit the loop if the task fails
  if [ "$TASK_STATUS" == "FAILED" ]; then
    echo "Audit task failed"
    exit 1
  fi
done

echo "Audit task completed successfully"

# Get audit findings
FINDINGS=$(aws iot list-audit-findings --task-id "$TASK_ID")
echo "Audit findings:"
echo "$FINDINGS"

# Check if we have any non-compliant findings
if echo "$FINDINGS" | grep -q '"findingId"'; then
  FINDING_ID=$(echo "$FINDINGS" | grep -o '"findingId": "[^"]*' | head -1 | cut -d'"' -f4)
  echo "Found non-compliant finding with ID: $FINDING_ID"
  HAS_FINDINGS=true
else
  echo "No non-compliant findings detected"
  HAS_FINDINGS=false
fi
```

## Step 4: Create a Mitigation Action

Now, let's create a mitigation action to address the findings. Mitigation actions are predefined actions that can be applied to non-compliant resources to resolve issues. In this case, we'll create an action to enable AWS IoT logging.

```bash
# Check if mitigation action already exists
MITIGATION_EXISTS=$(aws iot list-mitigation-actions --action-name "EnableErrorLoggingAction" 2>&1)
if echo "$MITIGATION_EXISTS" | grep -q "EnableErrorLoggingAction"; then
  echo "Mitigation action 'EnableErrorLoggingAction' already exists, deleting it first..."
  aws iot delete-mitigation-action --action-name "EnableErrorLoggingAction"
  # Wait a moment for deletion to complete
  sleep 5
fi

# Create a mitigation action to enable AWS IoT logging
aws iot create-mitigation-action \
  --action-name "EnableErrorLoggingAction" \
  --role-arn "$MITIGATION_ROLE_ARN" \
  --action-params "{\"enableIoTLoggingParams\":{\"roleArnForLogging\":\"$LOGGING_ROLE_ARN\",\"logLevel\":\"ERROR\"}}"

# Verify the mitigation action was created
aws iot describe-mitigation-action --action-name "EnableErrorLoggingAction"
```

AWS IoT Device Defender supports several types of mitigation actions:

- `enableIoTLoggingParams`: Enables AWS IoT logging
- `updateDeviceCertificateParams`: Updates a device certificate
- `updateCACertificateParams`: Updates a CA certificate
- `addThingsToThingGroupParams`: Adds devices to a thing group
- `replaceDefaultPolicyVersionParams`: Replaces the default version of a policy
- `publishFindingToSnsParams`: Publishes findings to an SNS topic

## Step 5: Apply Mitigation Actions to Findings

If the audit found any non-compliant resources, we can apply our mitigation action:

```bash
# Apply the mitigation action to the finding if any were found
if [ "$HAS_FINDINGS" = true ]; then
  MITIGATION_TASK_ID="MitigationTask-$(date +%s)"
  echo "Starting mitigation actions task with ID: $MITIGATION_TASK_ID"

  aws iot start-audit-mitigation-actions-task \
    --task-id "$MITIGATION_TASK_ID" \
    --target "{\"findingIds\":[\"$FINDING_ID\"]}" \
    --audit-check-to-actions-mapping "{\"LOGGING_DISABLED_CHECK\":[\"EnableErrorLoggingAction\"]}"

  echo "Mitigation actions task started successfully"

  # Wait for the mitigation task to complete
  echo "Waiting for mitigation task to complete..."
  sleep 10

  # List mitigation tasks
  MITIGATION_TASKS=$(aws iot list-audit-mitigation-actions-tasks \
    --start-time "$(date -d 'today' '+%Y-%m-%d')" \
    --end-time "$(date -d 'tomorrow' '+%Y-%m-%d')")

  echo "Mitigation tasks:"
  echo "$MITIGATION_TASKS"
else
  echo "No findings to mitigate"
fi
```

## Step 6: Set Up SNS Notifications (Optional)

To receive notifications about audit results, you can set up Amazon SNS notifications:

```bash
# Check if SNS topic already exists
SNS_TOPICS=$(aws sns list-topics)
if echo "$SNS_TOPICS" | grep -q "IoTDDNotifications"; then
  echo "SNS topic 'IoTDDNotifications' already exists, using existing topic..."
  TOPIC_ARN=$(echo "$SNS_TOPICS" | grep -o '"TopicArn": "[^"]*IoTDDNotifications' | cut -d'"' -f4)
else
  echo "Creating SNS topic for notifications..."
  SNS_RESULT=$(aws sns create-topic --name "IoTDDNotifications")
  TOPIC_ARN=$(echo "$SNS_RESULT" | grep -o '"TopicArn": "[^"]*' | cut -d'"' -f4)
  echo "SNS topic created with ARN: $TOPIC_ARN"
fi

# Update the audit configuration to enable SNS notifications
aws iot update-account-audit-configuration \
  --audit-notification-target-configurations "{\"SNS\":{\"targetArn\":\"$TOPIC_ARN\",\"roleArn\":\"$AUDIT_ROLE_ARN\",\"enabled\":true}}"

# Verify the notification configuration
aws iot describe-account-audit-configuration
```

To receive email notifications, you can subscribe an email address to the SNS topic:

```bash
# Subscribe an email address to the SNS topic (replace with your email)
aws sns subscribe \
  --topic-arn "$TOPIC_ARN" \
  --protocol email \
  --notification-endpoint "your-email@example.com"

echo "Check your email to confirm the subscription"
```

## Step 7: Enable AWS IoT Logging

Finally, let's enable AWS IoT logging to monitor IoT activity. AWS IoT supports two logging APIs: the newer v2 logging API and the legacy v1 API. We'll try v2 first and fall back to v1 if needed:

```bash
# Enable AWS IoT logging using v2 API (preferred)
echo "Setting up AWS IoT logging options..."

LOGGING_RESULT=$(aws iot set-v2-logging-options \
  --role-arn "$LOGGING_ROLE_ARN" \
  --default-log-level "ERROR" 2>&1)

# Check if v2 logging succeeded
if echo "$LOGGING_RESULT" | grep -q "error\|Error\|ERROR"; then
    echo "Failed to set up AWS IoT v2 logging, trying v1 logging..."

    # Create the logging options payload for v1 API
    LOGGING_OPTIONS_PAYLOAD="{\"roleArn\":\"$LOGGING_ROLE_ARN\",\"logLevel\":\"ERROR\"}"

    # Try the older set-logging-options command with proper payload format
    LOGGING_RESULT_V1=$(aws iot set-logging-options \
      --logging-options-payload "$LOGGING_OPTIONS_PAYLOAD" 2>&1)

    if echo "$LOGGING_RESULT_V1" | grep -q "error\|Error\|ERROR"; then
        echo "Failed to set up AWS IoT logging with both v1 and v2 methods"
        echo "V2 result: $LOGGING_RESULT"
        echo "V1 result: $LOGGING_RESULT_V1"
        exit 1
    else
        echo "AWS IoT v1 logging enabled successfully"
    fi
else
    echo "AWS IoT v2 logging enabled successfully"
fi

# Verify logging configuration
LOGGING_CONFIG=$(aws iot get-logging-options 2>/dev/null || aws iot get-v2-logging-options 2>/dev/null)
echo "Logging configuration:"
echo "$LOGGING_CONFIG"
```

The available log levels are:
- `DEBUG`: Most verbose logging level
- `INFO`: Informational messages
- `ERROR`: Error messages only
- `DISABLED`: No logging

**Note**: AWS IoT has two logging APIs:
- **V2 Logging API** (`set-v2-logging-options`): The newer, recommended API that provides more granular control
- **V1 Logging API** (`set-logging-options`): The legacy API that uses a JSON payload format

The v2 API is preferred, but some AWS regions or account configurations may require the v1 API.

## Cleaning Up Resources

When you're done with this tutorial, you can clean up the resources:

```bash
# Disable AWS IoT logging
echo "Disabling AWS IoT logging..."

# Try to disable v2 logging first
DISABLE_V2_RESULT=$(aws iot set-v2-logging-options \
  --default-log-level "DISABLED" 2>&1)

if echo "$DISABLE_V2_RESULT" | grep -q "error\|Error\|ERROR"; then
    echo "Failed to disable v2 logging, trying v1..."
    # Try v1 logging disable
    DISABLE_V1_RESULT=$(aws iot set-logging-options \
      --logging-options-payload "{\"logLevel\":\"DISABLED\"}" 2>&1)

    if echo "$DISABLE_V1_RESULT" | grep -q "error\|Error\|ERROR"; then
        echo "Warning: Could not disable logging through either v1 or v2 methods"
    else
        echo "V1 logging disabled successfully"
    fi
else
    echo "V2 logging disabled successfully"
fi

# Delete mitigation action
aws iot delete-mitigation-action --action-name "EnableErrorLoggingAction"

# Delete SNS topic
aws sns delete-topic --topic-arn "$TOPIC_ARN"

# Delete IAM roles and policies
# First, check if policies exist before trying to delete them
ROLE_POLICIES=$(aws iam list-role-policies --role-name "IoTMitigationActionErrorLoggingRole" 2>&1)
if ! echo "$ROLE_POLICIES" | grep -q "NoSuchEntity"; then
  if echo "$ROLE_POLICIES" | grep -q "IoTMitigationActionErrorLoggingRolePolicy"; then
    aws iam delete-role-policy \
      --role-name "IoTMitigationActionErrorLoggingRole" \
      --policy-name "IoTMitigationActionErrorLoggingRolePolicy"
  fi
fi
aws iam delete-role --role-name "IoTMitigationActionErrorLoggingRole"

ROLE_POLICIES=$(aws iam list-role-policies --role-name "AWSIoTLoggingRole" 2>&1)
if ! echo "$ROLE_POLICIES" | grep -q "NoSuchEntity"; then
  if echo "$ROLE_POLICIES" | grep -q "AWSIoTLoggingRolePolicy"; then
    aws iam delete-role-policy \
      --role-name "AWSIoTLoggingRole" \
      --policy-name "AWSIoTLoggingRolePolicy"
  fi
fi
aws iam delete-role --role-name "AWSIoTLoggingRole"

aws iam detach-role-policy \
  --role-name "AWSIoTDeviceDefenderAuditRole" \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AWSIoTDeviceDefenderAudit"
aws iam delete-role --role-name "AWSIoTDeviceDefenderAuditRole"

echo "Cleanup completed successfully"
```

## Troubleshooting

If you encounter issues during this tutorial, here are some common problems and solutions:

1. **Permission errors**: Make sure your AWS CLI user has the necessary permissions to create IAM roles and work with AWS IoT Device Defender.

2. **Role already exists**: If a role already exists, you can either use the existing role or delete and recreate it.

3. **Audit task fails**: Check the error message using `aws iot describe-audit-task --task-id "$TASK_ID"` for more details.

4. **Mitigation action fails**: Verify that the role has the correct permissions and that the parameters are correctly formatted.

## Conclusion

In this tutorial, you've learned how to:

1. Set up the necessary IAM roles for AWS IoT Device Defender
2. Enable audit checks to monitor your IoT environment
3. Run on-demand audits to identify compliance issues
4. Create and apply mitigation actions to address findings
5. Set up notifications for audit results
6. Enable and configure AWS IoT logging

AWS IoT Device Defender helps you secure your IoT fleet by continuously monitoring for security issues and providing mechanisms to address them. By following this tutorial, you've established a foundation for maintaining the security of your IoT devices and infrastructure.

## Going to Production

This tutorial is designed to help you understand how AWS IoT Device Defender works and how to use its basic features. However, for production environments, consider the following best practices:

### Security Best Practices

1. **IAM Role Refinement**: The IAM roles created in this tutorial follow the principle of least privilege, but you should further refine them for your specific use case. For example, limit the resources that the mitigation action role can access.

2. **Scheduled Audits**: Instead of running on-demand audits, set up scheduled audits to regularly check your IoT configuration:
   ```bash
   aws iot create-scheduled-audit \
     --scheduled-audit-name "DailyIoTAudit" \
     --frequency "DAILY" \
     --target-check-names LOGGING_DISABLED_CHECK DEVICE_CERTIFICATE_EXPIRING_CHECK \
     --day-of-week "MON"
   ```

3. **Enable All Relevant Audit Checks**: This tutorial only enables one audit check. In production, enable all checks relevant to your environment.

4. **Implement Detect Features**: Consider implementing the Detect feature of AWS IoT Device Defender to monitor device behavior in real-time.

5. **SNS Notification Encryption**: Enable encryption for your SNS topics that receive security findings.

### Architecture Best Practices

1. **Automated Remediation**: Implement automated remediation for common findings using AWS Lambda and Step Functions.

2. **Cross-Account Monitoring**: For large organizations, consider setting up cross-account monitoring with AWS Organizations.

3. **Integration with Security Hub**: Integrate AWS IoT Device Defender with AWS Security Hub for centralized security monitoring.

4. **Logging and Monitoring**: Set up comprehensive logging and monitoring for all IoT activities, not just the audit findings.

5. **Infrastructure as Code**: Use AWS CloudFormation or AWS CDK to manage your IoT Device Defender configuration as code.

For more information on production best practices, refer to:
- [AWS IoT Security Best Practices](https://docs.aws.amazon.com/iot/latest/developerguide/security-best-practices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

For more information on AWS IoT Device Defender, see the [AWS IoT Device Defender Developer Guide](https://docs.aws.amazon.com/iot-device-defender/latest/devguide/what-is-dd.html).
