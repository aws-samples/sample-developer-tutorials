# S3 Bucket Tagging

An AWS CLI tutorial that demonstrates S3 operations.

## Running

```bash
bash s3-bucket-tagging.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash s3-bucket-tagging.sh
```

## What it does

1. Creating bucket"; aws s3api create-bucket --bucket "$B
2. Adding tags"; aws s3api put-bucket-tagging --bucket "$B
3. Getting tags"; aws s3api get-bucket-tagging --bucket "$B
4. Deleting tags"; aws s3api delete-bucket-tagging --bucket "$B"; echo "  Tags deleted

## Resources created

- Bucket
- Bucket Tagging

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI s3 reference](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html)
- [AWS CLI s3api reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html)

