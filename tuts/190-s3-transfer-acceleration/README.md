# S3 Transfer Acceleration

An AWS CLI tutorial that demonstrates S3 operations.

## Running

```bash
bash s3-transfer-acceleration.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash s3-transfer-acceleration.sh
```

## What it does

1. Creating bucket
2. Enabling Transfer Acceleration
3. Getting acceleration status
4. Accelerated endpoint

## Resources created

- Bucket
- Bucket Accelerate Configuration

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI s3 reference](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html)
- [AWS CLI s3api reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html)

