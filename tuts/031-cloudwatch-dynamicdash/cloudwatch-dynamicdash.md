# Creating a CloudWatch dashboard with function name as a variable

This tutorial guides you through creating a CloudWatch dashboard that uses a property variable to display metrics for different Lambda functions. You'll learn how to create a dashboard with a dropdown menu that allows you to switch between Lambda functions without creating separate dashboards for each function.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. At least one Lambda function in your AWS account. If you don't have any Lambda functions, this tutorial includes steps to create a simple test function.
4. Sufficient permissions to create and manage CloudWatch dashboards and Lambda functions in your AWS account.

### Cost considerations

This tutorial uses AWS resources that are either included in the AWS Free Tier or have minimal costs:

- CloudWatch Dashboards: First 3 dashboards are free. Additional dashboards cost $3.00 per dashboard per month.
- CloudWatch Metrics: Standard metrics for AWS services like Lambda are included at no additional charge.
- CloudWatch API Calls: First 1 million API calls per month are free.

If you follow the cleanup instructions at the end of this tutorial, you should incur no charges or minimal charges.

## Create a CloudWatch dashboard

First, let's create a basic CloudWatch dashboard that will serve as the foundation for our dynamic dashboard with variables.

**Create an empty dashboard**

The following command creates a new empty CloudWatch dashboard:

```bash
aws cloudwatch put-dashboard --dashboard-name LambdaMetricsDashboard --dashboard-body '{
  "widgets": []
}'
```

This command creates a dashboard named "LambdaMetricsDashboard" with no widgets. The dashboard body is specified as a JSON string that defines the layout and content of the dashboard.

## Add Lambda metrics widgets with a function name variable

Now, let's create a more comprehensive dashboard that includes Lambda metrics widgets and a function name variable. We'll define the dashboard body in a JSON file for better readability.

**Create the dashboard body JSON file**

First, create a JSON file that defines the dashboard layout, widgets, and variables. Replace `us-east-1` in the region fields with your preferred AWS region:

```bash
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
          [ "AWS/Lambda", "Invocations", "FunctionName", "\${FunctionName}" ],
          [ ".", "Errors", ".", "." ],
          [ ".", "Throttles", ".", "." ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "Lambda Function Metrics for \${FunctionName}",
        "period": 300
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
          [ "AWS/Lambda", "Duration", "FunctionName", "\${FunctionName}", { "stat": "Average" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "Duration for \${FunctionName}",
        "period": 300
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
          [ "AWS/Lambda", "ConcurrentExecutions", "FunctionName", "\${FunctionName}" ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "us-east-1",
        "title": "Concurrent Executions for \${FunctionName}",
        "period": 300
      }
    }
  ],
  "periodOverride": "auto",
  "variables": [
    {
      "type": "property",
      "id": "FunctionName",
      "property": "FunctionName",
      "label": "Lambda Function",
      "inputType": "select",
      "values": [
        {
          "value": "my-lambda-function",
          "label": "my-lambda-function"
        }
      ]
    }
  ]
}
EOF
```

This JSON file defines a dashboard with three metric widgets that display different Lambda metrics: Invocations, Errors, Throttles, Duration, and Concurrent Executions. The dashboard also includes a variable named "FunctionName" that allows you to select different Lambda functions from a dropdown menu.

**Apply the dashboard configuration**

Now, apply this dashboard configuration using the following command:

```bash
aws cloudwatch put-dashboard --dashboard-name LambdaMetricsDashboard --dashboard-body file://dashboard-body.json
```

This command creates a dashboard with the specified widgets and variable. The `file://` prefix tells the AWS CLI to read the dashboard body from the specified file rather than treating it as a literal string.

## Verify the dashboard

After creating the dashboard, you can verify that it was created successfully and check its configuration.

**List all dashboards**

To see a list of all your CloudWatch dashboards, use the following command:

```bash
aws cloudwatch list-dashboards
```

This command returns a list of all dashboards in your account, including the one you just created.

**Get dashboard details**

To view the details of your specific dashboard, use the following command:

```bash
aws cloudwatch get-dashboard --dashboard-name LambdaMetricsDashboard
```

This command returns the full configuration of your dashboard, including the dashboard body JSON. You can verify that the variable and widgets are configured correctly.

## Access and use the dashboard in the console

While you've created the dashboard using the AWS CLI, you'll need to use the CloudWatch console to interact with the dropdown variable.

1. Open the CloudWatch console at https://console.aws.amazon.com/cloudwatch/
2. In the navigation pane, choose **Dashboards**
3. Select your **LambdaMetricsDashboard**
4. You should see a dropdown menu labeled "Lambda Function" at the top of the dashboard
5. Use this dropdown to select different Lambda functions and see their metrics displayed in the dashboard widgets

The dashboard will automatically update all widgets to show metrics for the selected Lambda function.

## Understanding the dashboard configuration

Let's break down the key components of the dashboard configuration:

**Widgets**

Each widget in the dashboard is configured to display specific Lambda metrics. The `${FunctionName}` placeholder in the metrics configuration is replaced with the value selected in the dropdown menu.

**Variables**

The `variables` section defines a property variable with the following attributes:

- `type`: "property" indicates this is a property variable
- `id`: The unique identifier for the variable
- `property`: The CloudWatch metric dimension that will be changed (FunctionName)
- `label`: The display label for the dropdown menu
- `inputType`: "select" creates a dropdown menu
- `values`: An array of values to populate the dropdown menu

When you select a different function from the dropdown, all widgets that use `${FunctionName}` in their configuration will update to show metrics for the selected function.

## Troubleshooting

Here are solutions to common issues you might encounter:

**Dashboard validation errors**

If you receive validation errors when creating the dashboard, check:
- The JSON syntax in your dashboard body
- That all required fields are present in the variable definition
- That the region specified in the widgets is valid

**Lambda functions not appearing in dropdown**

If Lambda functions don't appear in your dropdown:
- Verify that you have Lambda functions in your account
- Check that the functions have metrics available in CloudWatch
- Ensure you have permissions to view the Lambda metrics

**Metrics not displaying**

If metrics don't display for selected functions:
- Confirm the function has been invoked recently (Lambda metrics only appear after function invocation)
- Check that you're looking at the appropriate time range in the dashboard
- Verify that the region in the widget configuration matches the region where your Lambda functions are deployed

## Going to production

This tutorial demonstrates how to create a CloudWatch dashboard with a function name variable for educational purposes. When implementing this in a production environment, consider these additional best practices:

**Security considerations:**
- Implement proper IAM permissions to restrict who can view and modify dashboards
- Consider using resource tags to organize and control access to your dashboards
- Implement CloudWatch alarms for critical metrics to receive notifications when issues occur

**Architecture best practices:**
- For large environments, organize multiple dashboards by application or team
- Implement automated dashboard creation and updates using AWS CloudFormation or other IaC tools
- Consider cross-account and cross-region monitoring for distributed applications
- Implement a tagging strategy for Lambda functions to enable more sophisticated filtering

For more information on building production-ready monitoring solutions:
- [AWS Well-Architected Framework - Operational Excellence Pillar](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/welcome.html)
- [AWS Well-Architected Framework - Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
- [CloudWatch Best Practices](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html)

## Clean up resources

When you're finished with the dashboard, you can delete it to avoid cluttering your CloudWatch console.

**Delete the dashboard**

To delete the dashboard, use the following command:

```bash
aws cloudwatch delete-dashboards --dashboard-names LambdaMetricsDashboard
```

This command removes the dashboard from your account. The `delete-dashboards` command accepts multiple dashboard names, allowing you to delete multiple dashboards at once if needed.

Don't forget to delete the JSON file if you no longer need it:

```bash
rm dashboard-body.json
```

## Next steps

Now that you've learned how to create a CloudWatch dashboard with a function name variable, you can explore other CloudWatch features:

1. [Create composite alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Create_Composite_Alarm.html) to monitor multiple metrics and conditions.
2. [Create anomaly detection alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Create_Anomaly_Detection_Alarm.html) to automatically detect unusual behavior in your metrics.
3. [Use metric math](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html) to perform calculations on your metrics and create more advanced visualizations.
4. [Create cross-account dashboards](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch-crossaccount-dashboard.html) to monitor resources across multiple AWS accounts.
5. [Use CloudWatch Logs Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html) to analyze and visualize your log data alongside your metrics.
