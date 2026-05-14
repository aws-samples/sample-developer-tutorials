#!/bin/bash
set -e
REGION='us-east-1'
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/log.txt"
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
        RESOURCE=(${CREATED_RESOURCES[$i]})
        case ${RESOURCE[0]} in
            "group")
                aws scheduler delete-schedule-group --name ${RESOURCE[1]} --region ${REGION} || true
                ;;
            "schedule")
                aws scheduler delete-schedule --name ${RESOURCE[1]} --region ${REGION} || true
                ;;
        esac
    done
    rm -rf ${TEMP_DIR}
}
trap cleanup_resources EXIT

if [[! $(aws configure get region 2>/dev/null) == "$REGION" ]]; then
    echo "Region mismatch. Please configure AWS CLI with region ${REGION}."
    exit 1
fi

echo "=== Creating resources ==="
GROUP_NAME="group-${SUFFIX}"
SCHEDULE_NAME="schedule-${SUFFIX}"

echo "Creating schedule group: ${GROUP_NAME}"
GROUP_ARN=$(aws scheduler create-schedule-group --name ${GROUP_NAME} --query 'ScheduleGroupArn' --output text --region ${REGION})
echo "Schedule group created: ${GROUP_ARN}"
CREATED_RESOURCES+=("group:${GROUP_NAME}")

echo "Creating schedule: ${SCHEDULE_NAME}"
SCHEDULE_ARN=$(aws scheduler create-schedule --name ${SCHEDULE_NAME} --schedule-expression 'rate(5 minutes)' --target '{"Arn": "arn:aws:lambda:us-east-1:123456789012:function:MyFunction", "RoleArn": "arn:aws:iam::559823168634:role/doc-babu-scheduler-role"}' --flexible-time-window '{"Mode": "OFF"}' --query 'ScheduleArn' --output text --region ${REGION})
echo "Schedule created: ${SCHEDULE_ARN}"
CREATED_RESOURCES+=("schedule:${SCHEDULE_NAME}")

echo "=== Listing resources ==="
echo "Listing schedule groups:"
aws scheduler list-schedule-groups --query 'ScheduleGroups[].Name' --output text --region ${REGION}

echo "=== Deleting resources ==="
echo "PASS"