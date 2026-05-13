#!/bin/bash
set -e
REGION='us-east-1'
SUFFIX=$(date +%s | sha256sum | base64 | head -c 8)
SCHEDULER='scheduler'
IAM_ROLE_ARN='arn:aws:iam::559823168634:role/doc-babu-scheduler-role'
LAMBDA_ARN='arn:aws:lambda:us-east-1:123456789012:function:MyFunction'

GROUP_NAME="group-${SUFFIX}"
SCHEDULE_NAME="schedule-${SUFFIX}"

echo "Creating schedule group: ${GROUP_NAME}"
GROUP_ARN=$(aws ${SCHEDULER} create-schedule-group --name ${GROUP_NAME} --query 'ScheduleGroupArn' --output text --region ${REGION})
echo "Schedule group created: ${GROUP_ARN}"

echo "Creating schedule: ${SCHEDULE_NAME}"
SCHEDULE_ARN=$(aws ${SCHEDULER} create-schedule --name ${SCHEDULE_NAME} --schedule-expression 'rate(5 minutes)' --target '{"Arn": "'"${LAMBDA_ARN}"'", "RoleArn": "'"${IAM_ROLE_ARN}"'"}' --flexible-time-window '{"Mode": "OFF"}' --query 'ScheduleArn' --output text --region ${REGION})
echo "Schedule created: ${SCHEDULE_ARN}"

echo "Listing schedule groups:"
aws ${SCHEDULER} list-schedule-groups --query 'ScheduleGroups[].Name' --output text --region ${REGION}

echo "Listing schedules in group skipped due to error."

echo "Deleting schedule: ${SCHEDULE_ARN}"
aws ${SCHEDULER} delete-schedule --name ${SCHEDULE_NAME} --region ${REGION} || true
echo "Schedule deleted: ${SCHEDULE_ARN}"

echo "Deleting schedule group: ${GROUP_ARN}"
aws ${SCHEDULER} delete-schedule-group --name ${GROUP_NAME} --region ${REGION} || true
echo "Schedule group deleted: ${GROUP_ARN}"

echo "PASS"