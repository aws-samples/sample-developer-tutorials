# X-Ray Trace to CloudWatch Logs Insights

A powerful shell script that helps you find all Cloudwatch Logs associated to an AWS X-Ray trace and all its related traces.

## Prerequisites

### Required Tools
- **AWS CLI v2** - Install from [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **jq** - JSON processor for parsing AWS responses
- **bash** - Shell environment (macOS/Linux)
- **Standard Unix tools** - `date`, `base64` (usually pre-installed)

### AWS Configuration
1. **Configure AWS credentials:**

   This tool assumes your AWS CLI is logged in. For instance, if you're using AWS IAM Identity Center

   ```
    aws sso login
    export AWS_PROFILE = my-profile
   ```

2. **Required IAM permissions:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "xray:BatchGetTraces",
           "xray:GetTraceSummaries", 
           "xray:GetServiceGraph",
           "logs:StartQuery",
           "logs:GetQueryResults",
           "logs:DescribeLogGroups"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

## Usage

### Basic Syntax
```bash
./aws-xray-to-cloudwatch-logs-insights.sh <trace-id> <date> [--run] [--service-map]
```

### Parameters
- **`<trace-id>`** - AWS X-Ray trace ID (format: `1-xxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx`)
- **`<date>`** - Reference date (used for fallback, actual trace timestamp is auto-detected)
- **`--run`** - Execute the CloudWatch Logs query automatically
- **`--service-map`** - Display service architecture visualization

## Examples

### 1. Generate Query Only
```bash
./aws-xray-to-cloudwatch-logs-insights.sh "1-64f2b1c5-8a9e3d7f2b4c6e1a9f8d2c5b" "2024-12-15 14:30:22Z"
```

**Output:**
```
CloudWatch Logs Insights Query:
================================

SOURCE logGroups()
| fields @timestamp, @message
| filter @message like /1-64f2b1c5-8a9e3d7f2b4c6e1a9f8d2c5b/ or @message like /1-64f2b1c4-7b8c2e5f3a6d9c1e4b7a8d2f/
| sort @timestamp desc
| limit 1000

Time Range: 2024-12-15 14:25:22 to 2024-12-15 14:35:22 UTC
Related Traces Found: 15
```

### 2. Show Service Architecture
```bash
./aws-xray-to-cloudwatch-logs-insights.sh "1-64f2b1c5-8a9e3d7f2b4c6e1a9f8d2c5b" "2024-12-15 14:30:22Z" --service-map
```

**Output:**
```
Service Map:
════════════
┌──────────────────────────────────────────────────────────────────────────────┐
│ user-api-gateway                                                             │
│ AWS::Lambda                                                                  │
│ Requests: 5                                                                  │
│ Avg Time: 1250ms                                                             │
└──────────────────────────────────────────────────────────────────────────────┘
                                      ↓
┌──────────────────────────────────────────────────────────────────────────────┐
│ order-processing-service                                                     │
│ AWS::Lambda::Function                                                        │
│ Requests: 3                                                                  │
│ Avg Time: 850ms                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                      ↓
┌──────────────────────────────────────────────────────────────────────────────┐
│ https://sqs.us-east-1.amazonaws.com/123456789012/order-queue                 │
│ AWS::SQS::Queue                                                              │
│ Requests: 12                                                                 │
│ Avg Time: 45ms                                                               │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 3. Execute Query Automatically
```bash
./aws-xray-to-cloudwatch-logs-insights.sh "1-64f2b1c5-8a9e3d7f2b4c6e1a9f8d2c5b" "2024-12-15 14:30:22Z" --run
```

**Output:**
```
Query completed. Results:
========================
2024-12-15 14:30:45.123 | INFO Order processing started for customer 12345
---
2024-12-15 14:30:44.856 | DEBUG Validating payment method for order ORD-789
---
2024-12-15 14:30:44.234 | ERROR Payment validation failed: insufficient funds
---
```

### 4. Full Analysis Mode
```bash
./aws-xray-to-cloudwatch-logs-insights.sh "1-64f2b1c5-8a9e3d7f2b4c6e1a9f8d2c5b" "2024-12-15 14:30:22Z" --service-map --run
```

Shows service architecture, then executes the query and displays formatted results.

## How It Works

### 1. Trace Analysis
- Fetches the original trace using `batch-get-traces`
- Extracts actual timestamp from trace data (ignores user-provided date)
- Creates ±5 minute time window around the trace

### 2. Related Trace Discovery
- Analyzes trace links to find parent/child relationships
- Identifies truly related traces (not just concurrent ones)
- Builds comprehensive trace ID list

### 3. Service Map Generation
- Calls `get-service-graph` for the time window
- Visualizes service architecture with performance metrics
- Shows request counts and average response times

### 4. Log Query Generation
- Creates CloudWatch Logs Insights query using `SOURCE logGroups()`
- Searches across ALL log groups in your account
- Filters for messages containing any related trace IDs

## Make it your own

### Custom Time Windows
The script automatically uses the trace timestamp, but you can modify the time window by editing these lines:
```bash
START_TIME=$((START_TIME - 300))  # 5 minutes before
END_TIME=$((START_TIME + 600))    # 10 minutes total window
```

### Filtering Specific Log Groups
To search only specific log groups, modify the SOURCE command:
```bash
SOURCE logGroups(namePrefix: ['/aws/lambda/my-service'])
```

## Troubleshooting

### Common Errors

**"Invalid trace ID format"**
- Ensure trace ID follows format: `1-xxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx`
- Check for typos or missing characters

**"AWS credentials not configured"**
- Run `aws configure` to set up credentials
- Verify with `aws sts get-caller-identity`

**"Failed to fetch trace data"**
- Check if trace ID exists and is in the correct region
- Verify IAM permissions for X-Ray access
- Ensure trace is not older than 30 days (X-Ray retention limit)

### Performance Tips

1. **Use service map first** to understand architecture scope
2. **Check trace age** - older traces may have limited data
3. **Monitor costs** - CloudWatch Logs Insights charges per GB scanned
4. **Filter log groups** for large AWS accounts

## License

This tool is provided as-is for educational and operational purposes. Use in accordance with your organization's AWS usage policies.
