# Send traces and query them with AWS X-Ray

## Overview

In this tutorial, you use the AWS CLI to send trace segments to AWS X-Ray, query trace summaries, retrieve full trace details, create a trace group with a filter expression, and view the service graph. You then delete the group during cleanup.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- Python 3 installed (used to generate trace IDs and timestamps).
- An IAM principal with permissions for `xray:PutTraceSegments`, `xray:GetTraceSummaries`, `xray:BatchGetTraces`, `xray:CreateGroup`, `xray:DeleteGroup`, and `xray:GetServiceGraph`.

## Step 1: Send a trace segment

Generate a trace ID and send a segment representing an HTTP request, followed by a subsegment representing a downstream call.

```bash
TRACE_ID=$(python3 -c "import time,random;print(f'1-{int(time.time()):08x}-{random.randbytes(12).hex()}')")
NOW=$(python3 -c "import time;print(time.time())")
END=$(python3 -c "import time;print(time.time()+0.5)")

SEGMENT="{\"trace_id\":\"$TRACE_ID\",\"id\":\"$(openssl rand -hex 8)\",\"name\":\"tutorial-service\",\"start_time\":$NOW,\"end_time\":$END,\"http\":{\"request\":{\"method\":\"GET\",\"url\":\"https://example.com/api/items\"},\"response\":{\"status\":200}}}"

aws xray put-trace-segments --trace-segment-documents "$SEGMENT"
```

X-Ray trace IDs follow the format `1-<unix epoch hex>-<96-bit random hex>`. Each segment needs a unique 64-bit hex ID, a name, and start/end times as Unix epoch floats.

Send a subsegment linked to the parent segment:

```bash
PARENT_ID=$(echo "$SEGMENT" | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])")
SUBSEG="{\"trace_id\":\"$TRACE_ID\",\"id\":\"$(openssl rand -hex 8)\",\"name\":\"database-query\",\"start_time\":$NOW,\"end_time\":$END,\"parent_id\":\"$PARENT_ID\"}"
aws xray put-trace-segments --trace-segment-documents "$SUBSEG"
```

Subsegments use `parent_id` to link to their parent segment. This creates the hierarchy visible in the X-Ray trace map.

## Step 2: Get trace summaries

Query recent trace summaries. X-Ray takes a few seconds to index new traces.

```bash
START_TIME=$(python3 -c "import time;print(int(time.time()-60))")
END_TIME=$(python3 -c "import time;print(int(time.time()))")

aws xray get-trace-summaries \
    --start-time "$START_TIME" --end-time "$END_TIME" \
    --query 'TraceSummaries[:3].{TraceId:Id,Duration:Duration,Status:Http.HttpStatus,Method:Http.HttpMethod}' \
    --output table
```

Trace summaries include the trace ID, duration, HTTP status, and response time. Use `--filter-expression` to narrow results by service name, status code, or annotation.

## Step 3: Get full trace details

Retrieve the complete trace including all segments and subsegments.

```bash
aws xray batch-get-traces --trace-ids "$TRACE_ID" \
    --query 'Traces[0].Segments[].{Id:Id}' --output table
```

`batch-get-traces` returns the raw segment documents. You can retrieve up to 5 trace IDs per call.

## Step 4: Create a trace group

Create a group that filters traces by service name.

```bash
GROUP_NAME="tut-group-$(openssl rand -hex 4)"

GROUP_ARN=$(aws xray create-group --group-name "$GROUP_NAME" \
    --filter-expression 'service("tutorial-service")' \
    --query 'Group.GroupARN' --output text)
echo "Group ARN: $GROUP_ARN"
```

Groups let you organize traces by filter expression. Each group generates its own service graph and CloudWatch metrics.

## Step 5: Get the service graph

View the service graph for the time window containing your traces.

```bash
aws xray get-service-graph \
    --start-time "$START_TIME" --end-time "$END_TIME" \
    --query 'Services[].{Name:Name,Type:Type,Edges:Edges|length(@)}' \
    --output table
```

The service graph shows services as nodes and their connections as edges. It may take a few seconds after sending traces for the graph to populate.

## Cleanup

Delete the trace group. Trace data itself expires automatically based on your X-Ray retention settings (default 30 days).

```bash
aws xray delete-group --group-arn "$GROUP_ARN"
```

The script automates all steps including cleanup:

```bash
bash aws-xray-gs.sh
```

## Related resources

- [Sending trace data to X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-sendingdata.html)
- [Retrieving trace data](https://docs.aws.amazon.com/xray/latest/devguide/xray-api-gettingdata.html)
- [Using groups in X-Ray](https://docs.aws.amazon.com/xray/latest/devguide/xray-console-groups.html)
- [AWS X-Ray pricing](https://aws.amazon.com/xray/pricing/)
