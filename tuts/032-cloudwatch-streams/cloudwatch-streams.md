# Using property variables in CloudWatch dashboards to monitor multiple Lambda functions through the AWS CLI

This tutorial guides you through creating a CloudWatch dashboard that uses a property variable for Lambda function names. With this approach, you can create a flexible dashboard that allows you to switch between different Lambda functions using a dropdown menu.

## Topics

- [Prerequisites](#prerequisites)
- [Create Lambda functions for monitoring](#create-lambda-functions-for-monitoring)
- [Create a CloudWatch dashboard](#create-a-cloudwatch-dashboard)
- [Add a property variable to the dashboard](#add-a-property-variable-to-the-dashboard)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. [Sufficient permissions](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/auth-and-access-control-cw.html) to create and manage CloudWatch dashboards and Lambda functions in your AWS account.

**Time to complete:** Approximately 20-30 minutes

**Cost estimate:** The resources created in this tutorial will cost approximately $0.004 per hour if left running, primarily for the CloudWatch dashboard ($3.00 per month). The Lambda functions and metrics used fall within the AWS Free Tier limits for most accounts.

## Create Lambda functions for monitoring

To demonstrate the dashboard variable functionality, you'll need Lambda functions to monitor. In this section, you'll create two simple Lambda functions that will serve as examples for your dashboard.

**Create an IAM role for Lambda execution**

First, create an IAM role that allows Lambda to write logs to CloudWatch:

```bash
ROLE_NAME="LambdaDashboardRole"

# Create trust policy
cat > trust-policy.json << EOF
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

# Create the IAM role
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json

# Attach the Lambda basic execution policy
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Get the role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query "Role.Arn" --output text)
```

This creates an IAM role with the necessary permissions for Lambda to write logs to CloudWatch. The role ARN is stored in the `ROLE_ARN` variable for use in the next steps.

**Create Lambda function code**

Now, create a simple Python function that will be used for both Lambda functions:

```bash
# Create a simple Python function
cat > lambda_function.py << EOF
def handler(event, context):
    print("Lambda function executed successfully")
    return {
        'statusCode': 200,
        'body': 'Success'
    }
EOF

# Zip the function code
zip -j lambda_function.zip lambda_function.py
```

This creates a basic Lambda function that logs a message and returns a success response.

**Deploy the Lambda functions**

Deploy two Lambda functions using the same code but different names:

```bash
# Create first Lambda function
aws lambda create-function \
  --function-name TestFunction1 \
  --runtime python3.9 \
  --role $ROLE_ARN \
  --handler lambda_function.handler \
  --zip-file fileb://lambda_function.zip

# Create second Lambda function
aws lambda create-function \
  --function-name TestFunction2 \
  --runtime python3.9 \
  --role $ROLE_ARN \
  --handler lambda_function.handler \
  --zip-file fileb://lambda_function.zip
```

These commands create two identical Lambda functions with different names. Both functions use the IAM role created earlier.

**Generate metrics by invoking the functions**

To have some metrics to display in your dashboard, invoke each function:

```bash
# Invoke the first function
aws lambda invoke --function-name TestFunction1 --payload '{}' /dev/null

# Invoke the second function
aws lambda invoke --function-name TestFunction2 --payload '{}' /dev/null
```

These commands invoke both Lambda functions, which will generate invocation metrics that you can view in your dashboard.

## Create a CloudWatch dashboard

Now that you have Lambda functions with metrics, you can create a CloudWatch dashboard to visualize them.

**Create a basic dashboard**

First, create a simple dashboard with a widget showing Lambda invocation metrics.

Note: The `region` property in the widget configuration should match the AWS Region where your Lambda function is deployed. In this example, we use "us-west-2" as the target Region.

```bash
DASHBOARD_NAME="LambdaMetricsDashboard"

# Create dashboard JSON
cat > dashboard-body.json << EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/Lambda", "Invocations", "FunctionName", "TestFunction1" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-west-2",
        "title": "Lambda Invocations",
        "period": 300,
        "stat": "Sum",
        "annotations": {
            "horizontal": []
        }
      }
    }
  ]
}
EOF

# Create the dashboard
aws cloudwatch put-dashboard --dashboard-name $DASHBOARD_NAME --dashboard-body file://dashboard-body.json
```

This creates a CloudWatch dashboard with a single widget showing the invocation metrics for TestFunction1. The dashboard body is defined in JSON format, specifying the widget type, size, position, and the metrics to display.

**Verify the dashboard creation**

You can verify that your dashboard was created successfully by retrieving its details:

```bash
aws cloudwatch get-dashboard --dashboard-name $DASHBOARD_NAME
```

This command returns the dashboard body and confirms that the dashboard was created successfully.

## Add a property variable to the dashboard

Now, let's enhance the dashboard by adding a property variable for the Lambda function name. This will allow you to switch between different Lambda functions using a dropdown menu.

**Update the dashboard with a property variable**

The AWS CLI doesn't currently support directly creating dashboards with property variables in a straightforward way. You'll need to use the CloudWatch console to add the property variable:

1. Open the CloudWatch console at https://console.aws.amazon.com/cloudwatch/
2. Navigate to **Dashboards** and select your dashboard: LambdaMetricsDashboard
3. Choose **Actions** > **Variables** > **Create a variable**
4. Choose **Property variable**
5. For **Property that the variable changes**, choose **FunctionName
6. For **Input type**, choose **Select menu (dropdown)**
7. Choose **Use the results of a metric search**
8. Choose **Pre-built queries** > **Lambda** > **Errors**
9. Choose **By Function Name** and then choose **Search**
10. (Optional) Configure any secondary settings as desired:
    * To customize the name of your variable, enter a name in **Custom variable name**
    * To customize the label for the variable input field, enter a label in **Input label**
    * To set the default value for this variable, enter a function name in **Default value**
11. Choose **Create variable**

After completing these steps, your dashboard will have a dropdown menu at the top that allows you to select different Lambda functions. When you select a function from the dropdown, all widgets that use the FunctionName dimension will automatically update to show metrics for the selected function.

**Add more widgets that use the variable**

Once you've added the property variable through the console, you can add more widgets that use the same variable. For example, you might want to add widgets for errors and duration metrics as follows.

Note: Specify the region to the AWS Region where your Lambda functions are located. In this example, we use "us-west-2".

```bash
cat > dashboard-body-updated.json << EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/Lambda", "Invocations", "FunctionName", "\${functionName}" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-west-2",
        "title": "Lambda Invocations for \${functionName}",
        "period": 300,
        "stat": "Sum",
        "annotations": {
            "horizontal": []
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/Lambda", "Errors", "FunctionName", "\${functionName}" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-west-2",
        "title": "Lambda Errors for \${functionName}",
        "period": 300,
        "stat": "Sum",
        "annotations": {
          "horizontal": []
        }
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/Lambda", "Duration", "FunctionName", "\${functionName}" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-west-2",
        "title": "Lambda Duration for \${functionName}",
        "period": 300,
        "stat": "Average",
        "annotations": {
          "horizontal": []
        }
      }
    }
  ]
}
EOF

# Update the dashboard with the new widgets
aws cloudwatch put-dashboard \
  --dashboard-name $DASHBOARD_NAME \
  --dashboard-body file://dashboard-body-updated.json
```

Note that this JSON includes `${functionName}` placeholders that will be replaced with the selected function name from the dropdown menu. However, you'll need to use the CloudWatch console to update the dashboard with these widgets while preserving the property variable configuration.

**Troubleshooting tips**

If you encounter issues with the property variable:

1. **Variable not appearing**: Make sure you've selected "Property variable" and not "Query variable" when creating the variable.

2. **No values in dropdown**: If no values appear in the dropdown, try invoking your Lambda functions a few more times to generate more metrics data.

3. **Widgets not updating**: Ensure that your widget metrics use the exact same property name as your variable. The property name is case-sensitive.

4. **JSON syntax errors**: When updating the dashboard through the console, be careful with the JSON syntax. Missing commas or brackets can cause the update to fail.

## Clean up resources

When you're finished with this tutorial, you should clean up the resources you created to avoid incurring additional charges.

**Delete the CloudWatch dashboard**

```bash
aws cloudwatch delete-dashboards --dashboard-names $DASHBOARD_NAME
```

This command deletes the CloudWatch dashboard you created.

**Delete the Lambda functions**

```bash
# Delete the first Lambda function
aws lambda delete-function --function-name TestFunction1

# Delete the second Lambda function
aws lambda delete-function --function-name TestFunction2
```

These commands delete both Lambda functions created for this tutorial.

**Delete the IAM role**

```bash
# Detach the policy from the role
aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Delete the role
aws iam delete-role --role-name $ROLE_NAME
```

These commands detach the policy from the IAM role and then delete the role.

## Going to production

This tutorial demonstrates how to create a CloudWatch dashboard with property variables for educational purposes. When implementing similar solutions in production environments, consider the following best practices:

### Security considerations

1. **IAM permissions**: The tutorial uses the `AWSLambdaBasicExecutionRole` managed policy for simplicity. In production, follow the principle of least privilege by creating custom IAM policies that grant only the specific permissions required.

2. **Resource naming**: Use a consistent naming strategy for your resources that includes environment information (dev, test, prod) to avoid confusion.

### Architecture best practices

1. **Infrastructure as Code**: Instead of manually creating resources, use AWS CloudFormation, AWS CDK, or Terraform to define your infrastructure as code for better repeatability and version control.

2. **Dashboard organization**: For large-scale monitoring, organize your dashboards by service, team, or application to make them more manageable.

3. **Cross-account monitoring**: For multi-account environments, consider using [CloudWatch cross-account observability](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Unified-Cross-Account.html) to centralize your monitoring.

4. **Cost optimization**: Consolidate widgets where possible and use appropriate metric resolution to control CloudWatch costs.

For more information on AWS best practices, refer to:
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/whitepapers/latest/aws-security-best-practices/aws-security-best-practices.html)
- [CloudWatch Best Practices](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html)

## Next steps

Now that you've learned how to create a CloudWatch dashboard with property variables, explore other CloudWatch features:

1. [Create composite alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Create_Composite_Alarm.html) to monitor multiple metrics and conditions.
2. [Set up CloudWatch Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html) to analyze and visualize your log data.
3. [Create metric math expressions](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html) to perform calculations on your metrics.
4. [Use CloudWatch cross-account observability](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Unified-Cross-Account.html) to monitor resources across multiple AWS accounts.
5. [Create anomaly detection alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Create_Anomaly_Detection_Alarm.html) to identify unusual behavior in your metrics.
