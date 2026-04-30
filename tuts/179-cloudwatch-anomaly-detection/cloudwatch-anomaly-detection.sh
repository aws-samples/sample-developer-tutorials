#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/ad.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); NS="Tutorial/AD-${RANDOM_ID}"; ALARM="tut-ad-alarm-${RANDOM_ID}"
cleanup() { echo ""; echo "Cleaning up..."; aws cloudwatch delete-alarms --alarm-names "$ALARM" 2>/dev/null && echo "  Deleted alarm"; aws cloudwatch delete-anomaly-detector --namespace "$NS" --metric-name Latency --stat Average 2>/dev/null && echo "  Deleted detector"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Publishing baseline metrics"
for i in $(seq 1 20); do aws cloudwatch put-metric-data --namespace "$NS" --metric-name Latency --value $((50 + RANDOM % 20)) --unit Milliseconds; done
echo "  Published 20 data points"
echo "Step 2: Creating anomaly detector"
aws cloudwatch put-anomaly-detector --namespace "$NS" --metric-name Latency --stat Average 2>/dev/null && echo "  Detector created" || echo "  Detector creation pending"
echo "Step 3: Creating anomaly detection alarm"
aws cloudwatch put-metric-alarm --alarm-name "$ALARM" --namespace "$NS" --metric-name Latency --comparison-operator LessThanLowerOrGreaterThanUpperThreshold --evaluation-periods 1 --threshold-metric-id ad1 --metrics '[{"Id":"m1","MetricStat":{"Metric":{"Namespace":"'"$NS"'","MetricName":"Latency"},"Period":60,"Stat":"Average"},"ReturnData":true},{"Id":"ad1","Expression":"ANOMALY_DETECTION_BAND(m1,2)","ReturnData":true}]' 2>/dev/null && echo "  Alarm created" || echo "  Alarm creation requires more data"
echo "Step 4: Describing alarm"
aws cloudwatch describe-alarms --alarm-names "$ALARM" --query 'MetricAlarms[0].{Name:AlarmName,State:StateValue}' --output table 2>/dev/null || echo "  No alarm"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
