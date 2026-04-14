#!/bin/bash
# Tutorial: Create CloudWatch alarms and dashboards
# Source: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/GettingStarted.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/cloudwatch-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(openssl rand -hex 4)
ALARM_NAME="tut-alarm-${RANDOM_ID}"
DASHBOARD_NAME="tut-dashboard-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws cloudwatch delete-alarms --alarm-names "$ALARM_NAME" 2>/dev/null && echo "  Deleted alarm $ALARM_NAME"
    aws cloudwatch delete-dashboards --dashboard-names "$DASHBOARD_NAME" 2>/dev/null && echo "  Deleted dashboard $DASHBOARD_NAME"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Put custom metrics
echo "Step 1: Publishing custom metrics"
for i in $(seq 1 5); do
    VALUE=$((RANDOM % 100))
    aws cloudwatch put-metric-data --namespace "Tutorial/App" \
        --metric-name RequestLatency --value "$VALUE" --unit Milliseconds
done
echo "  Published 5 data points to Tutorial/App namespace"

# Step 2: Get metric statistics
echo "Step 2: Retrieving metric statistics"
sleep 2
aws cloudwatch get-metric-statistics \
    --namespace "Tutorial/App" --metric-name RequestLatency \
    --start-time "$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)" \
    --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --period 60 --statistics Average Maximum Minimum \
    --query 'Datapoints[0].{Avg:Average,Max:Maximum,Min:Minimum}' --output table 2>/dev/null || \
    echo "  Metrics not yet available (can take 1-2 minutes)"

# Step 3: Create an alarm
echo "Step 3: Creating alarm: $ALARM_NAME"
aws cloudwatch put-metric-alarm \
    --alarm-name "$ALARM_NAME" \
    --namespace "Tutorial/App" --metric-name RequestLatency \
    --statistic Average --period 60 \
    --threshold 80 --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --alarm-description "Tutorial alarm: latency > 80ms"
echo "  Alarm created (triggers when avg latency > 80ms)"

# Step 4: Describe the alarm
echo "Step 4: Alarm details"
aws cloudwatch describe-alarms --alarm-names "$ALARM_NAME" \
    --query 'MetricAlarms[0].{Name:AlarmName,State:StateValue,Threshold:Threshold,Metric:MetricName}' --output table

# Step 5: Create a dashboard
echo "Step 5: Creating dashboard: $DASHBOARD_NAME"
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
    }" > /dev/null
echo "  Dashboard created with 2 widgets"

# Step 6: List dashboards
echo "Step 6: Listing dashboards"
aws cloudwatch list-dashboards --dashboard-name-prefix "tut-" \
    --query 'DashboardEntries[].{Name:DashboardName,Size:Size}' --output table

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws cloudwatch delete-alarms --alarm-names $ALARM_NAME"
    echo "  aws cloudwatch delete-dashboards --dashboard-names $DASHBOARD_NAME"
fi
