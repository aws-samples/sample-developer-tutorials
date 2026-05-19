# AWS Scheduler Service Tutorial

This tutorial demonstrates how to create, list, and delete schedule groups and schedules using the AWS Scheduler service.

## Topics

- [Prerequisites](#aws-scheduler-service-tutorial-prerequisites)
- [Verify AWS CLI Configuration](#aws-scheduler-service-tutorial-verify-aws-cli-configuration)
- [Create Schedule Group](#aws-scheduler-service-tutorial-create-schedule-group)
- [Create Schedule](#aws-scheduler-service-tutorial-create-schedule)
- [List Schedule Groups](#aws-scheduler-service-tutorial-list-schedule-groups)
- [Clean up resources](#aws-scheduler-service-tutorial-clean-up-resources)
- [Next steps](#aws-scheduler-service-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/what-is-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces.
4. [Sufficient permissions](https://docs.aws.amazon.com/scheduler/latest/UserGuide/security_iam_id-based-policy-examples.html) to create, list, and delete schedule groups and schedules.

## Verify AWS CLI Configuration

Checking if the AWS CLI is configured with the correct region. This ensures that all operations are performed in the intended AWS region.

**Checking AWS CLI configuration:**

```bash
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
echo "AWS CLI is configured with region ${REGION}."
```

After running the command, ensure that the region displayed matches your intended AWS region.

## Create Schedule Group

Creating a schedule group is the first step in organizing your schedules. A schedule group helps in managing and categorizing related schedules.

**Creating a schedule group:**

```bash
GROUP_NAME="group-$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)"
echo "Creating schedule group: ${GROUP_NAME}"
GROUP_ARN=$(aws scheduler create-schedule-group --name ${GROUP_NAME} --query 'ScheduleGroupArn' --output text)
echo "Schedule group created: ${GROUP_ARN}"
```

After running the command, you should see the ARN of the created schedule group.

## Create Schedule

Creating a schedule allows you to define when and how often a task should run. This is crucial for automating repetitive tasks in your AWS environment.

**Creating a schedule:**

```bash
SCHEDULE_NAME="schedule-$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)"
echo "Creating schedule: ${SCHEDULE_NAME}"
SCHEDULE_ARN=$(aws scheduler create-schedule --name ${SCHEDULE_NAME} --schedule-expression 'rate(5 minutes)' --target '{"Arn": "arn:aws:lambda:us-east-1:123456789012:function:MyFunction", "RoleArn": "arn:aws:iam::559823168634:role/doc-babu-scheduler-role"}' --flexible-time-window '{"Mode": "OFF"}' --query 'ScheduleArn' --output text)
echo "Schedule created: ${SCHEDULE_ARN}"
```

After running the command, you should see the ARN of the created schedule.

## List Schedule Groups

Listing schedule groups helps you keep track of all the groups you have created. This is useful for managing and auditing your schedule groups.

**Listing schedule groups:**

```bash
echo "Listing schedule groups:"
aws scheduler list-schedule-groups --query 'ScheduleGroups[].Name' --output text
```

After running the command, you should see a list of all schedule groups you have created.

## Clean up resources

To clean up the resources created during this tutorial, the script includes a cleanup function that deletes the schedule group and schedule.

**Cleaning up resources:**

```bash
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
```

This ensures that all created resources are deleted when the script exits.

## Next steps

- Learn more about [managing schedule groups](https://docs.aws.amazon.com/scheduler/latest/UserGuide/managing-schedule-groups.html).
- Explore how to [create and manage schedules](https://docs.aws.amazon.com/scheduler/latest/UserGuide/managing-schedules.html).
- Understand [IAM permissions for AWS Scheduler](https://docs.aws.amazon.com/scheduler/latest/UserGuide/security_iam_id-based-policy-examples.html).