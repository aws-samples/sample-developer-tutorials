# CloudWatch Logs: Create log groups and query logs

## Overview

In this tutorial, you use the AWS CLI to create a CloudWatch Logs log group, send log events to it, and query the logs using both filter patterns and Logs Insights.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- An IAM principal with permissions for `logs:CreateLogGroup`, `logs:PutRetentionPolicy`, `logs:CreateLogStream`, `logs:PutLogEvents`, `logs:GetLogEvents`, `logs:FilterLogEvents`, `logs:StartQuery`, `logs:GetQueryResults`, and `logs:DeleteLogGroup`.

## Step 1: Create a log group

Create a log group to store your log events.

```bash
aws logs create-log-group \
    --log-group-name /tutorials/cloudwatch-logs-gs
```

## Step 2: Set retention to 7 days

Configure the log group to automatically expire log data after 7 days.

```bash
aws logs put-retention-policy \
    --log-group-name /tutorials/cloudwatch-logs-gs \
    --retention-in-days 7
```

## Step 3: Create a log stream

Create a log stream within the log group.

```bash
aws logs create-log-stream \
    --log-group-name /tutorials/cloudwatch-logs-gs \
    --log-stream-name app-stream
```

## Step 4: Put log events

Send five log events with a mix of INFO, WARN, and ERROR levels.

```bash
NOW=$(date +%s000)

aws logs put-log-events \
    --log-group-name /tutorials/cloudwatch-logs-gs \
    --log-stream-name app-stream \
    --log-events \
        timestamp=$NOW,message="[INFO] Application started successfully" \
        timestamp=$((NOW+1)),message="[INFO] Processing request batch" \
        timestamp=$((NOW+2)),message="[WARN] High memory usage detected" \
        timestamp=$((NOW+3)),message="[ERROR] Failed to connect to database" \
        timestamp=$((NOW+4)),message="[ERROR] Request timeout after 30s"
```

## Step 5: Get log events

Retrieve the log events from the stream.

```bash
aws logs get-log-events \
    --log-group-name /tutorials/cloudwatch-logs-gs \
    --log-stream-name app-stream
```

## Step 6: Filter for ERROR and WARN

Use a filter pattern to find only ERROR and WARN messages.

```bash
aws logs filter-log-events \
    --log-group-name /tutorials/cloudwatch-logs-gs \
    --filter-pattern "?ERROR ?WARN"
```

## Step 7: Run a Logs Insights query

Run a Logs Insights query to parse and count log events by level.

```bash
QUERY_ID=$(aws logs start-query \
    --log-group-name /tutorials/cloudwatch-logs-gs \
    --start-time $(date -d '1 hour ago' +%s) \
    --end-time $(date +%s) \
    --query-string 'fields @timestamp, @message | parse @message "[*] *" as level, msg | stats count(*) by level' \
    --output text --query 'queryId')

sleep 5

aws logs get-query-results \
    --query-id "$QUERY_ID"
```

## Cleanup

Delete the log group to remove all associated log streams and log data.

```bash
aws logs delete-log-group \
    --log-group-name /tutorials/cloudwatch-logs-gs
```

## Related resources

- [What is Amazon CloudWatch Logs?](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html)
- [CloudWatch Logs Insights query syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
- [Filter and pattern syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html)
