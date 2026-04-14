# EC2 Auto Scaling: Create an Auto Scaling group

## Source

<https://docs.aws.amazon.com/autoscaling/ec2/userguide/get-started-with-ec2-auto-scaling.html>

## Use case

| Field | Value |
|-------|-------|
| ID | `autoscaling/getting-started` |
| Level | Intermediate |
| Core actions | `autoscaling:CreateAutoScalingGroup`, `ec2:CreateLaunchTemplate` |

## What it does

1. Finds the latest Amazon Linux 2023 AMI.
2. Creates a launch template (`t2.micro`).
3. Gets available availability zones.
4. Creates an Auto Scaling group (min 1, max 3, desired 1).
5. Waits for the instance to reach `InService` and describes the group.
6. Cleans up: force-deletes the ASG and deletes the launch template.

## Running

```bash
# Read through the tutorial, then run each step:
cat amazon-ec2-autoscaling-gs.md

# Or run the script directly:
bash amazon-ec2-autoscaling-gs.sh
```

## Resources created

| Resource | Name/Detail |
|----------|-------------|
| Launch template | `my-asg-launch-template` |
| Auto Scaling group | `my-asg` (min 1, max 3, desired 1) |
| EC2 instance | 1× `t2.micro` (launched by the ASG) |

## Estimated time

~73 seconds (most time spent waiting for the instance to reach `InService`).

## Cost

- `t2.micro` is Free Tier eligible (750 hours/month for 12 months on new accounts).
- Outside the Free Tier, charges apply while the instance is running.
- Clean up promptly after completing the tutorial.

## Related docs

- [Amazon EC2 Auto Scaling User Guide](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)
- [Launch templates](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html)
- [Auto Scaling groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html)

---

## Appendix

