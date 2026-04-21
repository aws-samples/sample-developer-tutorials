# S3 Object Lock

An AWS CLI tutorial that demonstrates S3 operations.

## Running

```bash
bash s3-object-lock.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash s3-object-lock.sh
```

## What it does

1. Creating bucket with Object Lock
2. Setting default retention (1 day governance mode)
3. Getting lock configuration
4. Uploading a locked object
5. Verifying lock

## Resources created

- Bucket
- Bucket Versioning
- Object Lock Configuration

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI s3 reference](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html)
- [AWS CLI s3api reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html)

