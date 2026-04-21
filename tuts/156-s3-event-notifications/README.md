# S3 Events

An AWS CLI tutorial that demonstrates S3 operations.

## Running

```bash
bash s3-events.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash s3-events.sh
```

## What it does

1. Creating SQS queue for notifications
2. Creating bucket with event notification
3. Uploading a file to trigger notification
4. Reading notification from SQS

## Resources created

- Bucket
- Queue
- Bucket Notification Configuration

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI s3 reference](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html)
- [AWS CLI s3api reference](https://docs.aws.amazon.com/cli/latest/reference/s3api/index.html)
- [AWS CLI sqs reference](https://docs.aws.amazon.com/cli/latest/reference/sqs/index.html)

