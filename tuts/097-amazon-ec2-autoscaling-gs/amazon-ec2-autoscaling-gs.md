# EC2 Auto Scaling: Create an Auto Scaling group

This tutorial walks you through creating an Auto Scaling group with the AWS CLI. You create a launch template, configure an Auto Scaling group across availability zones, verify that an instance launches, then clean up all resources.

> **Cost note:** This tutorial launches a `t2.micro` EC2 instance, which is eligible for the AWS Free Tier. If you are outside the Free Tier, charges apply while the instance is running. Clean up promptly to avoid unnecessary costs.

## Prerequisites

- AWS CLI v2 installed and configured with credentials that have permissions for EC2 and Auto Scaling operations.
- A default VPC in your selected Region (most accounts have one).

## Step 1: Find the latest Amazon Linux 2023 AMI

Look up the latest Amazon Linux 2023 AMI ID for your Region using Systems Manager Parameter Store.

```bash
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-2023.*-x86_64" \
              "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text)

echo "AMI_ID=$AMI_ID"
```

## Step 2: Create a launch template

Create a launch template that specifies the AMI and instance type.

```bash
TEMPLATE_NAME="my-asg-launch-template"

aws ec2 create-launch-template \
    --launch-template-name "$TEMPLATE_NAME" \
    --launch-template-data "{\"ImageId\":\"$AMI_ID\",\"InstanceType\":\"t2.micro\"}"
```

## Step 3: Get availability zones

Retrieve the availability zones for your Region. The Auto Scaling group distributes instances across these zones.

```bash
AZ_LIST=$(aws ec2 describe-availability-zones \
    --query 'AvailabilityZones[?State==`available`].ZoneName' \
    --output text)

echo "AZ_LIST=$AZ_LIST"
```

The output is a space-separated list of availability zone names (for example, `us-east-1a us-east-1b us-east-1c`).

## Step 4: Create the Auto Scaling group

Create an Auto Scaling group with a minimum of 1 instance, a maximum of 3, and a desired capacity of 1.

```bash
ASG_NAME="my-asg"

aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name "$ASG_NAME" \
    --launch-template "LaunchTemplateName=$TEMPLATE_NAME" \
    --min-size 1 \
    --max-size 3 \
    --desired-capacity 1 \
    --availability-zones $AZ_LIST
```

Note that `--availability-zones` takes space-separated zone names, not comma-separated.

## Step 5: Wait for the instance and describe the group

Wait for the instance to reach the `InService` state, then describe the Auto Scaling group to confirm.

```bash
echo "Waiting for instance to be InService..."
aws autoscaling wait group-in-service \
    --auto-scaling-group-name "$ASG_NAME"

aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --query 'AutoScalingGroups[0].{Name:AutoScalingGroupName,Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Instances:Instances[*].{Id:InstanceId,State:LifecycleState}}' \
    --output table
```

## Step 6: Clean up

Delete the Auto Scaling group (force-deleting terminates running instances), then delete the launch template.

```bash
aws autoscaling delete-auto-scaling-group \
    --auto-scaling-group-name "$ASG_NAME" \
    --force-delete

echo "Waiting for instances to terminate..."
sleep 30

aws ec2 delete-launch-template \
    --launch-template-name "$TEMPLATE_NAME"

echo "Cleanup complete."
```

The `--force-delete` flag terminates all instances in the group before deleting it.

## Related resources

- [Amazon EC2 Auto Scaling User Guide — Get started](https://docs.aws.amazon.com/autoscaling/ec2/userguide/get-started-with-ec2-auto-scaling.html)
- [create-auto-scaling-group CLI reference](https://docs.aws.amazon.com/cli/latest/reference/autoscaling/create-auto-scaling-group.html)
- [create-launch-template CLI reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/create-launch-template.html)
