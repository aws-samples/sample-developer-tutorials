# Run CPU stress tests on EC2 instances using AWS FIS

This tutorial guides you through using AWS Fault Injection Service (AWS FIS) to run CPU stress tests on an Amazon EC2 instance. You'll learn how to create the necessary IAM roles, set up a CloudWatch alarm as a stop condition, create and run an experiment, and monitor the results.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with AWS services including IAM, EC2, CloudWatch, and AWS FIS.
4. [Sufficient permissions](https://docs.aws.amazon.com/fis/latest/userguide/security_iam_id-based-policy-examples.html) to create and manage IAM roles, EC2 instances, CloudWatch alarms, and FIS experiments.

**Time to complete:** Approximately 30-45 minutes

**Cost estimate:** Running this tutorial for one hour costs approximately $0.51, which includes:
- AWS FIS experiment ($0.10 per minute × 5 minutes = $0.50)
- EC2 t2.micro instance ($0.0116 per hour)
- CloudWatch detailed monitoring and alarm ($0.0006 per hour)

## Create IAM roles

AWS FIS needs permissions to perform actions on your behalf. In this section, you'll create the necessary IAM roles for both AWS FIS and the EC2 instance.

**Create an IAM role for AWS FIS**

First, create a trust policy file that allows AWS FIS to assume the role:

```bash
cat > fis-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "fis.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

This trust policy allows the AWS FIS service to assume the role you're creating.

Now, create the IAM role using the trust policy:

```bash
aws iam create-role \
  --role-name FISRole \
  --assume-role-policy-document file://fis-trust-policy.json
```

The response will include details about the newly created role.

Next, create a policy document that grants AWS FIS permission to send SSM commands:

```bash
cat > fis-ssm-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand"
      ],
      "Resource": [
        "arn:aws:ssm:*:*:document/AWSFIS-Run-CPU-Stress"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:SendCommand"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:instance/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Name": "FIS-Test-Instance"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:ListCommands",
        "ssm:ListCommandInvocations"
      ],
      "Resource": "*"
    }
  ]
}
EOF
```

This policy follows the principle of least privilege by restricting permissions to only what's needed for the tutorial.

Attach this policy to the role you created:

```bash
aws iam put-role-policy \
  --role-name FISRole \
  --policy-name FISPolicy \
  --policy-document file://fis-ssm-policy.json
```

**Create an IAM role for the EC2 instance**

Now, create a trust policy for the EC2 instance:

```bash
cat > ec2-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

Create the EC2 role using this trust policy:

```bash
aws iam create-role \
  --role-name EC2SSMRole \
  --assume-role-policy-document file://ec2-trust-policy.json
```

Attach the AmazonSSMManagedInstanceCore policy to allow Systems Manager to manage the instance:

```bash
aws iam attach-role-policy \
  --role-name EC2SSMRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

Create an instance profile and add the role to it:

```bash
aws iam create-instance-profile \
  --instance-profile-name EC2SSMProfile

aws iam add-role-to-instance-profile \
  --instance-profile-name EC2SSMProfile \
  --role-name EC2SSMRole
```

Wait a few seconds for the IAM role to propagate, then confirm that the role name was added to the instance profile:

```bash
sleep 10

aws iam list-instance-profiles-for-role \
  --role-name EC2SSMRole
```

## Launch an EC2 instance

In this section, you'll launch an EC2 instance that will be the target of your CPU stress test.

**Create a security group**

First, create a security group with minimal permissions:

```bash
SECURITY_GROUP_NAME="FIS-Test-SG"

# Create security group
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name "$SECURITY_GROUP_NAME" \
  --description "Security group for FIS test instance" \
  --query "GroupId" \
  --output text)

echo "Created security group: $SECURITY_GROUP_ID"

# Allow outbound traffic (required for SSM)
aws ec2 authorize-security-group-egress \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```

Output
```
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-098fc0f78d4112345",
            "GroupId": "sg-0b3a2cba820e12345",
            "GroupOwnerId": "123456789012",
            "IsEgress": true,
            "IpProtocol": "tcp",
            "FromPort": 443,
            "ToPort": 443,
            "CidrIpv4": "0.0.0.0/0"
        }
    ]
}

```

This security group allows only outbound HTTPS traffic, which is required for SSM communication.

**Find the latest Amazon Linux 2 AMI**

Find the latest Amazon Linux 2 AMI available in your region:

```bash
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text)

echo "Using AMI: $AMI_ID"
```

The command finds the most recent Amazon Linux 2 AMI and stores its ID in the AMI_ID variable.

**Launch the instance**

Now, launch an EC2 instance using the AMI, security group, and the instance profile you created:

```bash
TAGS='ResourceType=instance,Tags=[{Key=Name,Value=FIS-Test-Instance},{Key=Project,Value=FIS-Tutorial},{Key=Environment,Value=Test}]'

INSTANCE_OUTPUT=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --iam-instance-profile Name="EC2SSMProfile" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --tag-specifications "$TAGS")

INSTANCE_ID=$(echo "$INSTANCE_OUTPUT" | grep -i "InstanceId" | head -1 | awk -F'"' '{print $4}')
echo "Launched instance: $INSTANCE_ID"
```

This command launches a t2.micro instance with the EC2SSMProfile instance profile, the security group you created, and appropriate tags.

**Enable detailed monitoring**

Enable detailed monitoring for the instance to get more frequent CloudWatch metrics:

```bash
aws ec2 monitor-instances --instance-ids "$INSTANCE_ID"
```

Detailed monitoring provides CloudWatch metrics at 1-minute intervals instead of the default 5-minute intervals.

**Wait for the instance to be ready**

Wait for the instance to be running and pass its status checks:

```bash
echo "Waiting for instance to be ready..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID"
echo "Instance is ready"
```

## Create a CloudWatch alarm

In this section, you'll create a CloudWatch alarm that will act as a stop condition for your FIS experiment.

**Create the alarm**

Create a CloudWatch alarm that triggers when CPU utilization exceeds 50%:

```bash
ALARM_NAME="FIS-CPU-Alarm"

aws cloudwatch put-metric-alarm \
  --alarm-name "$ALARM_NAME" \
  --alarm-description "Alarm when CPU exceeds 50%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Maximum \
  --period 60 \
  --threshold 50 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --dimensions "Name=InstanceId,Value=$INSTANCE_ID" \
  --evaluation-periods 1
```

This alarm monitors the maximum CPU utilization of your instance and enters the ALARM state when it exceeds 50% for one minute.

**Get the alarm ARN**

Retrieve the ARN of the alarm you just created:

```bash
ALARM_ARN=$(aws cloudwatch describe-alarms \
  --alarm-names "$ALARM_NAME" \
  --query "MetricAlarms[0].AlarmArn" \
  --output text)

echo "Alarm ARN: $ALARM_ARN"
```

The alarm ARN will be used when creating the FIS experiment template.

**Wait for the alarm to initialize**

Wait for the CloudWatch alarm to initialize:

```bash
echo "Waiting for CloudWatch alarm to initialize (60 seconds)..."
sleep 60

# Check alarm state
ALARM_STATE=$(aws cloudwatch describe-alarms \
  --alarm-names "$ALARM_NAME" \
  --query "MetricAlarms[0].StateValue" \
  --output text)

echo "Current alarm state: $ALARM_STATE"

# If alarm is not in OK state, wait longer
if [ "$ALARM_STATE" != "OK" ]; then
    echo "Alarm not in OK state. Waiting for alarm to stabilize (additional 60 seconds)..."
    sleep 60

    ALARM_STATE=$(aws cloudwatch describe-alarms \
      --alarm-names "$ALARM_NAME" \
      --query "MetricAlarms[0].StateValue" \
      --output text)
    echo "Updated alarm state: $ALARM_STATE"
fi
```

This pause gives the alarm time to initialize and reach the OK state, which is required for the FIS experiment to start.

## Create an experiment template

In this section, you'll create an AWS FIS experiment template that defines the CPU stress test.

**Get the IAM role ARN**

First, get the ARN of the FIS IAM role you created earlier:

```bash
ROLE_ARN=$(aws iam get-role \
  --role-name FISRole \
  --query "Role.Arn" \
  --output text)

echo "Role ARN: $ROLE_ARN"
```

**Get the instance ARN**

Construct the ARN for your EC2 instance:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION=$(aws configure get region)
INSTANCE_ARN="arn:aws:ec2:${REGION}:${ACCOUNT_ID}:instance/${INSTANCE_ID}"

echo "Instance ARN: $INSTANCE_ARN"
```

**Create the experiment template**

Create a JSON file for the experiment template:

```bash
cat > experiment-template.json << EOF
{
  "description": "Test CPU stress predefined SSM document",
  "targets": {
    "testInstance": {
      "resourceType": "aws:ec2:instance",
      "resourceArns": ["$INSTANCE_ARN"],
      "selectionMode": "ALL"
    }
  },
  "actions": {
    "runCpuStress": {
      "actionId": "aws:ssm:send-command",
      "parameters": {
        "documentArn": "arn:aws:ssm:$REGION::document/AWSFIS-Run-CPU-Stress",
        "documentParameters": "{\"DurationSeconds\":\"120\"}",
        "duration": "PT5M"
      },
      "targets": {
        "Instances": "testInstance"
      }
    }
  },
  "stopConditions": [
    {
      "source": "aws:cloudwatch:alarm",
      "value": "$ALARM_ARN"
    }
  ],
  "roleArn": "$ROLE_ARN",
  "tags": {
    "Name": "FIS-CPU-Stress-Experiment"
  }
}
EOF
```

This template defines an experiment that:
- Targets your EC2 instance
- Runs the AWSFIS-Run-CPU-Stress SSM document with a duration of 120 seconds
- Stops if the CloudWatch alarm enters the ALARM state
- Uses the FIS IAM role you created

Now, create the experiment template:

```bash
TEMPLATE_OUTPUT=$(aws fis create-experiment-template --cli-input-json file://experiment-template.json)
TEMPLATE_ID=$(echo "$TEMPLATE_OUTPUT" | grep -i "id" | head -1 | awk -F'"' '{print $4}')

echo "Experiment template created with ID: $TEMPLATE_ID"
```

The template ID will be used to start the experiment.

## Run the experiment

In this section, you'll start the experiment and track its progress.

**Start the experiment**

Start the experiment using the template ID:

```bash
EXPERIMENT_OUTPUT=$(aws fis start-experiment \
  --experiment-template-id "$TEMPLATE_ID" \
  --tags '{"Name": "FIS-CPU-Stress-Run"}')

EXPERIMENT_ID=$(echo "$EXPERIMENT_OUTPUT" | grep -i "id" | head -1 | awk -F'"' '{print $4}')
echo "Experiment started with ID: $EXPERIMENT_ID"
```

This command starts the experiment and tags it with the name "FIS-CPU-Stress-Run".

**Track the experiment progress**

Wait a few minutes for the experiment to finish running. Check the experiment status:

```
aws fis get-experiment --id "$EXPERIMENT_ID"
```

When the experiment reaches a terminal state (completed, stopped, or failed), proceed to the next step.

## Verify the results

In this section, you'll check the CloudWatch alarm state and CPU metrics to verify the experiment's impact.

**Check the CloudWatch alarm state**

Check the state of the CloudWatch alarm:

```bash
aws cloudwatch describe-alarms --alarm-names "$ALARM_NAME"
```

The output will show whether the alarm entered the ALARM state during the experiment. If the experiment was successful, you should see that the alarm state changed to ALARM when the CPU utilization exceeded 50%.

**Get CPU utilization metrics**

Retrieve CPU utilization metrics for the instance:

```bash
END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Cross-platform compatible way to calculate time 10 minutes ago
CURRENT_EPOCH=$(date +%s)
TEN_MINUTES_AGO_EPOCH=$((CURRENT_EPOCH - 600))
START_TIME=$(date -u -d "@$TEN_MINUTES_AGO_EPOCH" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -r "$TEN_MINUTES_AGO_EPOCH" +"%Y-%m-%dT%H:%M:%SZ")

cat > metric-query.json << EOF
[
  {
    "Id": "cpu",
    "MetricStat": {
      "Metric": {
        "Namespace": "AWS/EC2",
        "MetricName": "CPUUtilization",
        "Dimensions": [
          {
            "Name": "InstanceId",
            "Value": "$INSTANCE_ID"
          }
        ]
      },
      "Period": 60,
      "Stat": "Maximum"
    }
  }
]
EOF

aws cloudwatch get-metric-data \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --metric-data-queries file://metric-query.json
```

This command retrieves the maximum CPU utilization metrics for your instance over the past 10 minutes. You should see a spike in CPU utilization during the experiment, which likely triggered the CloudWatch alarm.

## Troubleshooting

If you encounter issues during this tutorial, here are some common problems and solutions:

1. **Experiment fails to start**
   - Ensure the CloudWatch alarm is in the OK state before starting the experiment
   - Verify that the IAM role has the necessary permissions
   - Check that the instance is managed by SSM (verify the SSM agent is running)

2. **SSM command fails to execute**
   - Ensure the instance has outbound internet access to communicate with SSM
   - Verify that the SSM agent is installed and running on the instance
   - Check the SSM command history in the AWS Systems Manager console

3. **CloudWatch alarm doesn't trigger**
   - Verify that detailed monitoring is enabled for the instance
   - Check that the alarm is configured correctly with the right threshold
   - Ensure the CPU stress test is actually increasing CPU utilization

## Clean up resources

When you're finished with the tutorial, clean up the resources to avoid incurring additional charges.

**Delete the experiment template**

Delete the FIS experiment template:

```bash
aws fis delete-experiment-template --id "$TEMPLATE_ID"
```

**Delete the CloudWatch alarm**

Delete the CloudWatch alarm:

```bash
aws cloudwatch delete-alarms --alarm-names "$ALARM_NAME"
```

**Terminate the EC2 instance**

Terminate the EC2 instance:

```bash
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
echo "Waiting for instance to terminate..."
aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
```

**Delete the security group**

Delete the security group:

```bash
aws ec2 delete-security-group --group-id "$SECURITY_GROUP_ID"
```

**Clean up IAM resources**

Remove the role from the instance profile:

```bash
aws iam remove-role-from-instance-profile \
  --instance-profile-name EC2SSMProfile \
  --role-name EC2SSMRole
```

Delete the instance profile:

```bash
aws iam delete-instance-profile \
  --instance-profile-name EC2SSMProfile
```

Delete the FIS role policy:

```bash
aws iam delete-role-policy \
  --role-name FISRole \
  --policy-name FISPolicy
```

Detach the policy from the EC2 role:

```bash
aws iam detach-role-policy \
  --role-name EC2SSMRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

Delete the IAM roles:

```bash
aws iam delete-role --role-name FISRole
aws iam delete-role --role-name EC2SSMRole
```

**Clean up temporary files**

Remove the temporary JSON files:

```bash
rm -f fis-trust-policy.json ec2-trust-policy.json fis-ssm-policy.json experiment-template.json metric-query.json
```

## Going to production

This tutorial is designed to help you learn how AWS FIS works in a test environment. For production deployments, consider these additional best practices:

### Security considerations

1. **IAM permissions**: Further restrict IAM permissions using resource-level permissions and conditions
2. **VPC isolation**: Run experiments in isolated VPCs with appropriate network controls
3. **Encryption**: Use AWS KMS to encrypt sensitive data and CloudWatch logs
4. **Tagging strategy**: Implement a comprehensive tagging strategy for all resources
5. **Secrets management**: Use AWS Secrets Manager for any credentials or sensitive configuration

### Architecture considerations

1. **Multi-instance testing**: Test distributed applications across multiple instances
2. **Infrastructure as Code**: Use AWS CloudFormation or AWS CDK to define and deploy resources
3. **Observability**: Implement comprehensive monitoring with CloudWatch, X-Ray, and other tools
4. **Automation**: Integrate fault injection testing into CI/CD pipelines
5. **Resilience testing**: Test across multiple availability zones and regions

For more information on building production-ready systems on AWS, see:
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [Implementing Microservices on AWS](https://docs.aws.amazon.com/whitepapers/latest/microservices-on-aws/microservices-on-aws.html)

## Next steps

Now that you've learned how to run CPU stress tests using AWS FIS, explore other fault injection scenarios:

1. [Memory stress tests](https://docs.aws.amazon.com/fis/latest/userguide/actions-ssm-agent.html#awsfis-run-memory-stress) - Test how your applications handle memory pressure
2. [IO stress tests](https://docs.aws.amazon.com/fis/latest/userguide/actions-ssm-agent.html#awsfis-run-io-stress) - Test how your applications handle disk I/O stress
3. [Network latency](https://docs.aws.amazon.com/fis/latest/userguide/actions-ssm-agent.html#awsfis-add-network-latency) - Test how your applications handle network latency
4. [Network packet loss](https://docs.aws.amazon.com/fis/latest/userguide/actions-ssm-agent.html#awsfis-add-network-packet-loss) - Test how your applications handle network packet loss
5. [AWS service disruptions](https://docs.aws.amazon.com/fis/latest/userguide/fis-actions-reference.html) - Test how your applications handle AWS service disruptions

For more information about AWS FIS, see the [AWS Fault Injection Service User Guide](https://docs.aws.amazon.com/fis/latest/userguide/what-is.html).
