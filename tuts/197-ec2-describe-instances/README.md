# Ec2 Describe Instances

A read-only script that queries Ec2 resources and displays information.

## Running

```bash
bash ec2-describe-instances.sh
```

## What it does

1. Listing all instances"; aws ec2 describe-instances --query 'Reservations[].Instances[].{Id:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[?Key==`Name`].Value|[0]}' --output table 2>/dev/null || echo "  No instances
2. Counting by state

## Resources created

None — this script is read-only.

## Cost

No cost. This script only reads existing resources.

## Related docs

- [AWS CLI ec2 reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html)

