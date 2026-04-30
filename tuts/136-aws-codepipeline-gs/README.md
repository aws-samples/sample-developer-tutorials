# Aws Codepipeline Gs

An AWS CLI tutorial that demonstrates Codepipeline operations.

## Running

```bash
bash aws-codepipeline-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash aws-codepipeline-gs.sh
```

## What it does

1. Creating S3 bucket for artifacts
2. Creating IAM role
3. Creating pipeline: $PIPE_NAME
4. Getting pipeline state
5. Listing pipelines

## Resources created

- Bucket
- Pipeline
- Role
- Role Policy

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI codepipeline reference](https://docs.aws.amazon.com/cli/latest/reference/codepipeline/index.html)
- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)
- [AWS CLI s3 reference](https://docs.aws.amazon.com/cli/latest/reference/s3/index.html)

