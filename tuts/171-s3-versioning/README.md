# S3 Versioning

An AWS CLI tutorial that demonstrates S3 operations.

## Running

```bash
bash s3-versioning.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash s3-versioning.sh
```

## What it does

1. Creating versioned bucket
2. Uploading multiple versions
3. Listing versions
4. Getting a specific version
5. Deleting (creates delete marker)

## Resources created

- Bucket
- Bucket Versioning

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI s3 reference](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html)
- [AWS CLI s3api reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html)

