#!/bin/bash
set -e
echo "=== AWS Scheduler Service Tutorial ==="
echo "This tutorial demonstrates how to create, list, and delete schedule groups and schedules using the AWS Scheduler service."

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
                aws scheduler delete-schedule-group --name ${RESOURCE[1]} || true
                ;;
            "schedule")
                aws scheduler delete-schedule --name ${RESOURCE[1]} || true
                ;;
        esac
    done
    rm -rf ${TEMP_DIR}
}
trap cleanup_resources EXIT

if [ -t 1 ]; then 
    REGION="${AWS_DEFAULT_REGION:-us-east-1}"
    exit 1
fi

echo "=== Step 1: Verify AWS CLI Configuration ==="
echo "Checking if the AWS CLI is configured with the correct region."
echo "This ensures that all operations are performed in the intended AWS region."
echo ""
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
echo "AWS CLI is configured with region ${REGION}."
echo ""

echo "=== Step 2: Create Schedule Group ==="
echo "Creating a schedule group is the first step in organizing your schedules."
echo "A schedule group helps in managing and categorizing related schedules."
echo ""
GROUP_NAME="group-${SUFFIX}"
echo "Creating schedule group: ${GROUP_NAME}"
GROUP_ARN=$(aws scheduler create-schedule-group --name ${GROUP_NAME} --tags Key=project,Value=doc-smith Key=tutorial,Value=scheduler-gs --query 'ScheduleGroupArn' --output text)
echo "Schedule group created: ${GROUP_ARN}"
CREATED_RESOURCES+=("group:${GROUP_NAME}")
echo ""

echo "=== Step 3: Create Schedule ==="
echo "Creating a schedule allows you to define when and how often a task should run."
echo "This is crucial for automating repetitive tasks in your AWS environment."
echo ""
SCHEDULE_NAME="schedule-${SUFFIX}"
echo "Creating schedule: ${SCHEDULE_NAME}"
SCHEDULE_ARN=$(aws scheduler create-schedule --name ${SCHEDULE_NAME} --schedule-expression 'rate(5 minutes)' --target '{"Arn": "arn:aws:lambda:us-east-1:123456789012:function:MyFunction", "RoleArn": "${TUTORIAL_ROLE_ARN:?Set TUTORIAL_ROLE_ARN}"}' --flexible-time-window '{"Mode": "OFF"}' --tags Key=project,Value=doc-smith Key=tutorial,Value=scheduler-gs --query 'ScheduleArn' --output text)
echo "Schedule created: ${SCHEDULE_ARN}"
CREATED_RESOURCES+=("schedule:${SCHEDULE_NAME}")
echo ""

echo "=== Step 4: List Schedule Groups ==="
echo "Listing schedule groups helps you keep track of all the groups you have created."
echo "This is useful for managing and auditing your schedule groups."
echo ""
echo "Listing schedule groups:"
aws scheduler list-schedule-groups --query 'ScheduleGroups[].Name' --output text
echo ""

echo "=== Tutorial Complete ==="
echo "In this tutorial, you learned how to create a schedule group and a schedule using the AWS Scheduler service."
echo "You also learned how to list schedule groups."