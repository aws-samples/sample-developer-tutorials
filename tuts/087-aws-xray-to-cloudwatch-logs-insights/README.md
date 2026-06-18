# AWS X-Ray to CloudWatch Logs Insights

This tutorial demonstrates how to analyze AWS X-Ray traces and generate CloudWatch Logs Insights queries to find related log entries across your entire AWS infrastructure. You'll learn how to extract trace relationships, visualize service architecture, and automatically create comprehensive log queries for distributed system troubleshooting.

## Key Features

The script provides the following capabilities:

- **Trace Analysis**: Extracts actual timestamps and related trace IDs from X-Ray data
- **Service Mapping**: Visualizes service architecture with performance metrics
- **Query Generation**: Creates CloudWatch Logs Insights queries for all related traces
- **Automatic Execution**: Optionally runs queries and formats results
- **Error Handling**: Comprehensive validation and timeout protection

## Usage Modes

- **Query Generation**: `./aws-xray-to-cloudwatch-logs-insights.sh <trace-id> <date>` - Generates CloudWatch Logs Insights query
- **Service Visualization**: `./aws-xray-to-cloudwatch-logs-insights.sh <trace-id> <date> --service-map` - Shows service architecture
- **Automatic Execution**: `./aws-xray-to-cloudwatch-logs-insights.sh <trace-id> <date> --run` - Executes query and displays results
- **Full Analysis**: `./aws-xray-to-cloudwatch-logs-insights.sh <trace-id> <date> --service-map --run` - Complete analysis workflow