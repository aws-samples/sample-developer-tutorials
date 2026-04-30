# S3 Access Points

An AWS CLI tutorial that demonstrates S3 operations.

## Running

```bash
bash s3-access-points.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash s3-access-points.sh
```

## What it does

1. Creating bucket
2. Creating access point: $AP_NAME
3. Getting access point details
4. Listing access points

## Resources created

- Access Point
- Bucket

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI s3 reference](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html)
- [AWS CLI s3api reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html)
- [AWS CLI s3control reference](https://docs.aws.amazon.com/cli/latest/reference/s3control/index.html)

