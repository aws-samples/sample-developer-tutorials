# Ec2 Cost Optimization

A read-only script that queries Ec2 resources and displays information.

## Running

```bash
bash ec2-cost-optimization.sh
```

## What it does

1. Finding stopped instances (still incurring EBS charges)
2. Finding unattached EBS volumes
3. Finding unattached Elastic IPs
4. Finding old snapshots (>90 days)

## Resources created

None — this script is read-only.

## Cost

No cost. This script only reads existing resources.

## Related docs

- [AWS CLI ec2 reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html)

