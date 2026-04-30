# S3 Metrics

A read-only script that queries Cloudwatch resources and displays information.

## Running

```bash
bash s3-metrics.sh
```

## What it does

1. Listing buckets with sizes
2. Getting bucket metrics (request count)

## Resources created

None — this script is read-only.

## Cost

No cost. This script only reads existing resources.

## Related docs

- [AWS CLI cloudwatch reference](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/index.html)
- [AWS CLI s3api reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html)

