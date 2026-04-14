#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/cw-math.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); NS="Tutorial/App-${RANDOM_ID}"
cleanup() { echo ""; echo "No cleanup needed — custom metrics expire automatically."; rm -rf "$WORK_DIR"; }
echo "Step 1: Publishing high-resolution metrics"
for i in $(seq 1 10); do
    aws cloudwatch put-metric-data --namespace "$NS" --metric-data "[{\"MetricName\":\"Requests\",\"Value\":$((RANDOM % 100 + 50)),\"Unit\":\"Count\",\"StorageResolution\":1},{\"MetricName\":\"Errors\",\"Value\":$((RANDOM % 5)),\"Unit\":\"Count\",\"StorageResolution\":1},{\"MetricName\":\"Latency\",\"Value\":$((RANDOM % 200 + 10)),\"Unit\":\"Milliseconds\"}]"
done
echo "  Published 30 data points (10 batches x 3 metrics)"
sleep 3
echo "Step 2: Getting metric statistics"
aws cloudwatch get-metric-statistics --namespace "$NS" --metric-name Requests --start-time "$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)" --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --period 60 --statistics Sum Average Maximum --query 'Datapoints[0].{Sum:Sum,Avg:Average,Max:Maximum}' --output table 2>/dev/null || echo "  Metrics not yet available"
echo "Step 3: Using metric math (error rate)"
aws cloudwatch get-metric-data --metric-data-queries '[{"Id":"requests","MetricStat":{"Metric":{"Namespace":"'"$NS"'","MetricName":"Requests"},"Period":60,"Stat":"Sum"},"ReturnData":false},{"Id":"errors","MetricStat":{"Metric":{"Namespace":"'"$NS"'","MetricName":"Errors"},"Period":60,"Stat":"Sum"},"ReturnData":false},{"Id":"error_rate","Expression":"(errors/requests)*100","Label":"Error Rate %","ReturnData":true}]' --start-time "$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)" --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --query 'MetricDataResults[0].{Label:Label,Values:Values}' --output table 2>/dev/null || echo "  Math expression result pending"
echo "Step 4: Listing metrics in namespace"
aws cloudwatch list-metrics --namespace "$NS" --query 'Metrics[].{Name:MetricName,Dimensions:Dimensions|length(@)}' --output table
echo ""; echo "Tutorial complete."
cleanup
