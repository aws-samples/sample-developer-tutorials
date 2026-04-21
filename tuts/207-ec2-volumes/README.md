# Ec2 Volumes

A read-only script that queries Ec2 resources and displays information.

## Running

```bash
bash ec2-volumes.sh
```

## What it does

1. Listing volumes
2. Volume summary"; echo "  Total: $(aws ec2 describe-volumes --query 'Volumes | length(@)' --output text) volumes

## Resources created

None — this script is read-only.

## Cost

No cost. This script only reads existing resources.

## Related docs

- [AWS CLI ec2 reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html)

