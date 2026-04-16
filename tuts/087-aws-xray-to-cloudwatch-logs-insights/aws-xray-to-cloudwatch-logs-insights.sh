#!/bin/bash

#
# X-Ray Trace Log Analysis Tool
# 
# Analyzes AWS X-Ray traces and generates CloudWatch Logs Insights queries
# to find related log entries across your entire AWS infrastructure.
#
# Features:
# - Automatic trace timestamp extraction and time window calculation
# - Related trace discovery through parent/child relationships
# - Service architecture visualization with performance metrics
# - CloudWatch Logs Insights query generation and execution
# - Searches across all log groups in your AWS account
#
# Usage:
#   ./aws-xray-to-cloudwatch-logs-insights.sh <trace-id> <date> [--run] [--service-map]
#
# Examples:
#   ./aws-xray-to-cloudwatch-logs-insights.sh "1-64f2b1c5-8a9e3d7f2b4c6e1a9f8d2c5b" "2024-12-15 14:30:22Z"
#   ./aws-xray-to-cloudwatch-logs-insights.sh "1-64f2b1c5-8a9e3d7f2b4c6e1a9f8d2c5b" "2024-12-15 14:30:22Z" --service-map --run
#
# Author: @Paul Santus
# Version: 1.0
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Check dependencies
command -v aws >/dev/null 2>&1 || { echo "Error: AWS CLI required but not installed"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq required but not installed"; exit 1; }
command -v date >/dev/null 2>&1 || { echo "Error: date command required"; exit 1; }
command -v base64 >/dev/null 2>&1 || { echo "Error: base64 command required"; exit 1; }

# Usage: ./xray-trace-logs.sh <trace-id> <date> [--run] [--service-map]
if [ $# -lt 2 ] || [ $# -gt 4 ]; then
    echo "Usage: $0 <trace-id> <date> [--run] [--service-map]"
    echo "Example: $0 1-68c1a2a4-254e272a518953ead4d8f44a '2025-09-10 16:09:14Z'"
    echo "         $0 1-68c1a2a4-254e272a518953ead4d8f44a '2025-09-10 16:09:14Z' --run"
    echo "         $0 1-68c1a2a4-254e272a518953ead4d8f44a '2025-09-10 16:09:14Z' --service-map"
    echo "         $0 1-68c1a2a4-254e272a518953ead4d8f44a '2025-09-10 16:09:14Z' --run --service-map"
    exit 1
fi

TRACE_ID="$1"
USER_DATE="$2"

# Input validation
if [[ ! "$TRACE_ID" =~ ^1-[0-9a-f]{8}-[0-9a-f]{24}$ ]]; then
    echo "Error: Invalid trace ID format. Expected format: 1-xxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx"
    exit 1
fi
RUN_QUERY=""
SHOW_SERVICE_MAP=""

# Parse flags
for arg in "$@"; do
    case $arg in
        --run)
            RUN_QUERY="--run"
            ;;
        --service-map)
            SHOW_SERVICE_MAP="--service-map"
            ;;
    esac
done

# Get AWS region from CLI profile
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    echo "Error: AWS region not configured. Run 'aws configure' first."
    exit 1
fi

# Verify AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "Error: AWS credentials not configured or invalid. Run 'aws configure' first."
    exit 1
fi

# Get trace details to extract actual timestamp
echo "Fetching trace details for: $TRACE_ID"
if ! TRACE_DATA=$(aws xray batch-get-traces --region "$AWS_REGION" --trace-ids "$TRACE_ID" --query 'Traces[0]' --output json 2>/dev/null); then
    echo "Error: Failed to fetch trace data. Check AWS permissions and trace ID."
    exit 1
fi

if [ "$TRACE_DATA" == "null" ]; then
    echo "Error: Trace ID not found"
    exit 1
fi

# Extract start time from trace data and create time range (±5 minutes)
START_TIME=$(echo "$TRACE_DATA" | jq -r '.Segments[0].Document' | jq -r '.start_time')
START_TIME=${START_TIME%.*}  # Remove decimal part
START_TIME=$((START_TIME - 300))
END_TIME=$((START_TIME + 600))

# Convert to date format for display
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS date command
    START_DATE=$(date -u -r "$START_TIME" '+%Y-%m-%d %H:%M:%S')
    END_DATE=$(date -u -r "$END_TIME" '+%Y-%m-%d %H:%M:%S')
else
    # Linux date command
    START_DATE=$(date -u -d "@$START_TIME" '+%Y-%m-%d %H:%M:%S')
    END_DATE=$(date -u -d "@$END_TIME" '+%Y-%m-%d %H:%M:%S')
fi

# Get service map for the time range to find related services
echo "Using time range: $START_DATE to $END_DATE UTC"
echo "Fetching service map..."
SERVICE_MAP=$(aws xray get-service-graph --region "$AWS_REGION" --start-time "$START_TIME" --end-time "$END_TIME" --query 'Services[].Name' --output text)

# Display service map visualization if requested
if [ "$SHOW_SERVICE_MAP" = "--service-map" ]; then
    echo ""
    echo "Service Map:"
    echo "════════════"
    aws xray get-service-graph --region "$AWS_REGION" --start-time "$START_TIME" --end-time "$END_TIME" --output json | \
    jq -r '
    .Services[] | 
    select(.Type != "client") |
    (.Name | if length > 74 then .[0:71] + "..." else . end) as $shortName |
    (.SummaryStatistics.TotalCount | tostring) as $requests |
    ((.SummaryStatistics.TotalResponseTime / .SummaryStatistics.TotalCount * 1000 | floor) | tostring) + "ms" as $avgTime |
    "┌──────────────────────────────────────────────────────────────────────────────┐\n" +
    "│ " + ($shortName + (" " * (76 - ($shortName | length)))) + " │\n" +
    "│ " + (.Type | if length > 76 then .[0:73] + "..." else . + (" " * (76 - (. | length))) end) + " │\n" +
    "│ Requests: " + $requests + (" " * (67 - ($requests | length))) + "│\n" +
    "│ Avg Time: " + $avgTime + (" " * (67 - ($avgTime | length))) + "│\n" +
    "└──────────────────────────────────────────────────────────────────────────────┘\n" +
    "                                      ↓"
    '
    echo ""
fi

# Get all traces in the time window
echo "Fetching related traces..."
RELATED_TRACES=$(aws xray get-trace-summaries --region "$AWS_REGION" \
    --start-time "$START_TIME" \
    --end-time "$END_TIME" \
    --query 'TraceSummaries[].Id' \
    --output text)

# Extract linked trace IDs from the original trace
echo "Extracting linked traces..."
LINKED_TRACES=$(echo "$TRACE_DATA" | jq -r '.Segments[].Document' | jq -r 'select(.links != null) | .links[].trace_id' 2>/dev/null | sort -u)

# Combine original trace ID with linked traces
ALL_RELATED_TRACES="$TRACE_ID"
if [ -n "$LINKED_TRACES" ]; then
    ALL_RELATED_TRACES="$ALL_RELATED_TRACES $LINKED_TRACES"
fi

# Convert trace IDs to array and create filter (always include original trace ID)
TRACE_ARRAY=($ALL_RELATED_TRACES)
TRACE_FILTER="@message like /$TRACE_ID/"

for trace in $LINKED_TRACES; do
    if [ "$trace" != "$TRACE_ID" ]; then
        TRACE_FILTER="$TRACE_FILTER or @message like /$trace/"
    fi
done

# Generate CloudWatch Logs Insights query
QUERY_STRING="SOURCE logGroups()
| fields @timestamp, @message
| filter $TRACE_FILTER
| sort @timestamp desc
| limit 1000"

if [ "$RUN_QUERY" = "--run" ]; then
    echo "Running CloudWatch Logs Insights query across all log groups..."
    
    if ! QUERY_ID=$(aws logs start-query \
        --region "$AWS_REGION" \
        --start-time "$START_TIME" \
        --end-time "$END_TIME" \
        --query-string "$QUERY_STRING" \
        --query 'queryId' \
        --output text 2>/dev/null); then
        echo "Error: Failed to start CloudWatch Logs query. Check permissions."
        exit 1
    fi
    
    echo "Query started with ID: $QUERY_ID"
    echo "Waiting for query to complete..."
    
    # Wait for query to complete and fetch results with timeout
    TIMEOUT=300  # 5 minutes
    ELAPSED=0
    while [ $ELAPSED -lt $TIMEOUT ]; do
        if ! STATUS=$(aws logs get-query-results --region "$AWS_REGION" --query-id "$QUERY_ID" --query 'status' --output text 2>/dev/null); then
            echo "Error: Failed to check query status"
            exit 1
        fi
        
        if [ "$STATUS" = "Complete" ]; then
            echo "Query completed. Results:"
            echo "========================"
            aws logs get-query-results --region "$AWS_REGION" --query-id "$QUERY_ID" --query 'results' --output json 2>/dev/null | \
            jq -r '.[] | @base64' | while read -r line; do
                echo "$line" | base64 -d | jq -r '
                    . as $fields |
                    ($fields[] | select(.field == "@timestamp") | .value) as $timestamp |
                    ($fields[] | select(.field == "@message") | .value) as $message |
                    "\($timestamp) | \($message)"
                '
                echo "---"
            done
            break
        elif [ "$STATUS" = "Failed" ]; then
            echo "Query failed"
            exit 1
        else
            sleep 2
            ELAPSED=$((ELAPSED + 2))
        fi
    done
    
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "Error: Query timed out after $TIMEOUT seconds"
        exit 1
    fi
else
    cat << EOF

CloudWatch Logs Insights Query:
================================

SOURCE logGroups()
| fields @timestamp, @message
| filter $TRACE_FILTER
| sort @timestamp desc
| limit 1000

Time Range: $START_DATE to $END_DATE UTC
Related Traces Found: ${#TRACE_ARRAY[@]}

To run this query:
aws logs start-query \\
    --start-time $START_TIME \\
    --end-time $END_TIME \\
    --query-string '$QUERY_STRING'

EOF
fi