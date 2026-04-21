# S3 Presigned

An AWS CLI tutorial that demonstrates S3 operations.

## Running

```bash
bash s3-presigned.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash s3-presigned.sh
```

## What it does

1. Creating bucket
2. Uploading a file
3. Generating presigned download URL (expires in 5 min)
4. Testing presigned download
5. Generating presigned upload URL
6. Listing objects

## Resources created

- Bucket

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI s3 reference](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html)
- [AWS CLI s3api reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html)

