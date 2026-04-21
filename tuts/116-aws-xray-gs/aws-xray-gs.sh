#!/bin/bash
# Tutorial: Send traces and query them with AWS X-Ray
# Source: https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/xray-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
GROUP_NAME="tut-group-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    [ -n "$GROUP_ARN" ] && aws xray delete-group --group-arn "$GROUP_ARN" 2>/dev/null && echo "  Deleted group $GROUP_NAME"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Send a trace segment
echo "Step 1: Sending trace segments"
TRACE_ID=$(python3 -c "import time,random;print(f'1-{int(time.time()):08x}-{random.randbytes(12).hex()}')")
NOW=$(python3 -c "import time;print(time.time())")
END=$(python3 -c "import time;print(time.time()+0.5)")

SEGMENT="{\"trace_id\":\"$TRACE_ID\",\"id\":\"$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)\",\"name\":\"tutorial-service\",\"start_time\":$NOW,\"end_time\":$END,\"http\":{\"request\":{\"method\":\"GET\",\"url\":\"https://example.com/api/items\"},\"response\":{\"status\":200}}}"

aws xray put-trace-segments --trace-segment-documents "$SEGMENT" \
    --query 'UnprocessedTraceSegments' --output text
echo "  Trace ID: $TRACE_ID"

# Send a subsegment
PARENT_ID=$(echo "$SEGMENT" | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])")
SUBSEG="{\"trace_id\":\"$TRACE_ID\",\"id\":\"$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)\",\"name\":\"database-query\",\"start_time\":$NOW,\"end_time\":$END,\"parent_id\":\"$PARENT_ID\"}"
aws xray put-trace-segments --trace-segment-documents "$SUBSEG" > /dev/null 2>&1
echo "  Sent parent segment + subsegment"

# Step 2: Get trace summaries
echo "Step 2: Getting trace summaries"
sleep 5
START_TIME=$(python3 -c "import time;print(int(time.time()-60))")
END_TIME=$(python3 -c "import time;print(int(time.time()))")
aws xray get-trace-summaries \
    --start-time "$START_TIME" --end-time "$END_TIME" \
    --query 'TraceSummaries[:3].{TraceId:Id,Duration:Duration,Status:Http.HttpStatus,Method:Http.HttpMethod}' --output table 2>/dev/null || \
    echo "  No traces found yet (indexing can take a few seconds)"

# Step 3: Get full trace
echo "Step 3: Getting full trace"
aws xray batch-get-traces --trace-ids "$TRACE_ID" \
    --query 'Traces[0].Segments[].{Id:Id}' --output table 2>/dev/null || \
    echo "  Trace not yet indexed"

# Step 4: Create a group
echo "Step 4: Creating trace group: $GROUP_NAME"
GROUP_ARN=$(aws xray create-group --group-name "$GROUP_NAME" \
    --filter-expression 'service("tutorial-service")' \
    --query 'Group.GroupARN' --output text)
echo "  Group ARN: $GROUP_ARN"

# Step 5: Get service graph
echo "Step 5: Getting service graph"
aws xray get-service-graph \
    --start-time "$START_TIME" --end-time "$END_TIME" \
    --query 'Services[].{Name:Name,Type:Type,Edges:Edges|length(@)}' --output table 2>/dev/null || \
    echo "  No service graph available yet"

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws xray delete-group --group-arn $GROUP_ARN"
fi
