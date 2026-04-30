#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing alarms"; aws cloudwatch describe-alarms --query 'MetricAlarms[:10].{Name:AlarmName,State:StateValue,Metric:MetricName,Threshold:Threshold}' --output table
echo "Step 2: Alarm summary by state"
echo "  OK: $(aws cloudwatch describe-alarms --state-value OK --query 'MetricAlarms | length(@)' --output text)"
echo "  ALARM: $(aws cloudwatch describe-alarms --state-value ALARM --query 'MetricAlarms | length(@)' --output text)"
echo "  INSUFFICIENT_DATA: $(aws cloudwatch describe-alarms --state-value INSUFFICIENT_DATA --query 'MetricAlarms | length(@)' --output text)"
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
