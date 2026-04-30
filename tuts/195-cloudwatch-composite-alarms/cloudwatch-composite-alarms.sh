#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); NS="Tutorial/Comp-${RANDOM_ID}"; A1="tut-cpu-${RANDOM_ID}"; A2="tut-mem-${RANDOM_ID}"; COMP="tut-composite-${RANDOM_ID}"
cleanup() { echo "Cleaning up..."; aws cloudwatch delete-alarms --alarm-names "$COMP" "$A1" "$A2" 2>/dev/null && echo "  Deleted alarms"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Publishing metrics"
for i in $(seq 1 5); do aws cloudwatch put-metric-data --namespace "$NS" --metric-data "[{\"MetricName\":\"CPU\",\"Value\":$((RANDOM%100)),\"Unit\":\"Percent\"},{\"MetricName\":\"Memory\",\"Value\":$((RANDOM%100)),\"Unit\":\"Percent\"}]"; done
echo "Step 2: Creating metric alarms"
aws cloudwatch put-metric-alarm --alarm-name "$A1" --namespace "$NS" --metric-name CPU --statistic Average --period 60 --threshold 80 --comparison-operator GreaterThanThreshold --evaluation-periods 1
aws cloudwatch put-metric-alarm --alarm-name "$A2" --namespace "$NS" --metric-name Memory --statistic Average --period 60 --threshold 80 --comparison-operator GreaterThanThreshold --evaluation-periods 1
echo "Step 3: Creating composite alarm"
aws cloudwatch put-composite-alarm --alarm-name "$COMP" --alarm-rule "ALARM(\"$A1\") AND ALARM(\"$A2\")"
echo "  Composite alarm triggers when BOTH CPU and Memory are high"
echo "Step 4: Describing composite alarm"
aws cloudwatch describe-alarms --alarm-names "$COMP" --alarm-types CompositeAlarm --query 'CompositeAlarms[0].{Name:AlarmName,Rule:AlarmRule,State:StateValue}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && cleanup
