# Create alarms and dashboards with Amazon CloudWatch

## Overview

In this tutorial, you use the AWS CLI to publish custom metrics, retrieve statistics, create an alarm, and build a dashboard with metric widgets. You then clean up all resources.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- An IAM principal with permissions for `cloudwatch:PutMetricData`, `cloudwatch:GetMetricStatistics`, `cloudwatch:PutMetricAlarm`, `cloudwatch:DescribeAlarms`, `cloudwatch:DeleteAlarms`, `cloudwatch:PutDashboard`, `cloudwatch:ListDashboards`, and `cloudwatch:DeleteDashboards`.

## Step 1: Publish custom metrics

Publish five data points to a custom namespace.

```bash
RANDOM_ID=$(openssl rand -hex 4)

for i in $(seq 1 5); do
    VALUE=$((RANDOM % 100))
    aws cloudwatch put-metric-data --namespace "Tutorial/App" \
        --metric-name RequestLatency --value "$VALUE" --unit Milliseconds
done
```

Custom metrics appear in the `Tutorial/App` namespace. Each `put-metric-data` call can include up to 1,000 data points.

## Step 2: Retrieve metric statistics

Query the average, maximum, and minimum values over the last 5 minutes.

```bash
aws cloudwatch get-metric-statistics \
    --namespace "Tutorial/App" --metric-name RequestLatency \
    --start-time "$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)" \
    --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --period 60 --statistics Average Maximum Minimum \
    --query 'Datapoints[0].{Avg:Average,Max:Maximum,Min:Minimum}' --output table
```

Newly published metrics can take 1–2 minutes to appear in statistics queries.

## Step 3: Create an alarm

Create an alarm that triggers when average latency exceeds 80 milliseconds.

```bash
ALARM_NAME="tut-alarm-${RANDOM_ID}"

aws cloudwatch put-metric-alarm \
    --alarm-name "$ALARM_NAME" \
    --namespace "Tutorial/App" --metric-name RequestLatency \
    --statistic Average --period 60 \
    --threshold 80 --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --alarm-description "Tutorial alarm: latency > 80ms"
```

The alarm evaluates one 60-second period. Add `--alarm-actions` with an SNS topic ARN to send notifications when the alarm triggers.

## Step 4: Describe the alarm

View the alarm's current state and configuration.

```bash
aws cloudwatch describe-alarms --alarm-names "$ALARM_NAME" \
    --query 'MetricAlarms[0].{Name:AlarmName,State:StateValue,Threshold:Threshold,Metric:MetricName}' \
    --output table
```

New alarms start in `INSUFFICIENT_DATA` state until enough data points are collected for evaluation.

## Step 5: Create a dashboard

Create a dashboard with two metric widgets showing average and maximum latency.

```bash
DASHBOARD_NAME="tut-dashboard-${RANDOM_ID}"
REGION=$(aws configure get region)

aws cloudwatch put-dashboard --dashboard-name "$DASHBOARD_NAME" \
    --dashboard-body "{
        \"widgets\": [
            {\"type\":\"metric\",\"x\":0,\"y\":0,\"width\":12,\"height\":6,
             \"properties\":{\"metrics\":[[\"Tutorial/App\",\"RequestLatency\"]],
             \"period\":60,\"stat\":\"Average\",\"region\":\"$REGION\",\"title\":\"Request Latency\"}},
            {\"type\":\"metric\",\"x\":12,\"y\":0,\"width\":12,\"height\":6,
             \"properties\":{\"metrics\":[[\"Tutorial/App\",\"RequestLatency\"]],
             \"period\":60,\"stat\":\"Maximum\",\"region\":\"$REGION\",\"title\":\"Max Latency\"}}
        ]
    }"
```

Dashboard widgets reference metrics by namespace and metric name. The dashboard updates automatically as new data points arrive.

## Step 6: List dashboards

List dashboards matching the tutorial prefix.

```bash
aws cloudwatch list-dashboards --dashboard-name-prefix "tut-" \
    --query 'DashboardEntries[].{Name:DashboardName,Size:Size}' --output table
```

## Cleanup

Delete the alarm and dashboard. Custom metric data expires automatically based on its age (high-resolution data after 3 hours, 1-minute data after 15 days).

```bash
aws cloudwatch delete-alarms --alarm-names "$ALARM_NAME"
aws cloudwatch delete-dashboards --dashboard-names "$DASHBOARD_NAME"
```

The script automates all steps including cleanup:

```bash
bash amazon-cloudwatch-gs.sh
```

## Related resources

- [Getting started with CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/GettingStarted.html)
- [Using Amazon CloudWatch alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
- [Using CloudWatch dashboards](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Dashboards.html)
- [Publishing custom metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html)
