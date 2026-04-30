# S3 List Buckets

A read-only script that queries S3Api resources and displays information.

## Running

```bash
bash s3-list-buckets.sh
```

## What it does

1. Listing all buckets
2. Bucket count"; echo "  Total: $(aws s3api list-buckets --query 'Buckets | length(@)' --output text) buckets
3. Checking public access block"; B=$(aws s3api list-buckets --query 'Buckets[0].Name' --output text); [ -n "$B" ] && [ "$B" != "None" ] && aws s3api get-public-access-block --bucket "$B" --query 'PublicAccessBlockConfiguration' --output table 2>/dev/null || echo "  No public access block

## Resources created

None — this script is read-only.

## Cost

No cost. This script only reads existing resources.

## Related docs

- [AWS CLI s3api reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html)

