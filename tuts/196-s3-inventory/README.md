# S3 Inventory

An AWS CLI tutorial that demonstrates S3 operations.

## Running

```bash
bash s3-inventory.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash s3-inventory.sh
```

## What it does

1. Creating source and destination buckets
2. Configuring inventory
3. Getting inventory configuration

## Resources created

- Bucket
- Bucket Inventory Configuration

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI s3 reference](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html)
- [AWS CLI s3api reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html)

