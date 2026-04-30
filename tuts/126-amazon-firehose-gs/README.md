# Amazon Firehose Gs

An AWS CLI tutorial that demonstrates Firehose operations.

## Running

```bash
bash amazon-firehose-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash amazon-firehose-gs.sh
```

## What it does

1. Creating S3 bucket: $BUCKET
2. Creating IAM role
3. Creating delivery stream: $STREAM_NAME
4. Sending records
5. Describing stream

## Resources created

- Bucket
- Delivery Stream
- Role
- Record
- Record Batch

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI firehose reference](https://docs.aws.amazon.com/cli/latest/reference/firehose/index.html)
- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)
- [AWS CLI s3 reference](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html)

