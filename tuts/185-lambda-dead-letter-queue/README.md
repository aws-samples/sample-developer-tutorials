# Lambda Dead Letter

An AWS CLI tutorial that demonstrates Iam operations.

## Running

```bash
bash lambda-dead-letter.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash lambda-dead-letter.sh
```

## What it does

1. Creating function that always fails
2. Invoking async (will fail and go to DLQ)
3. Checking DLQ (after retries, ~3 min)

## Resources created

- Function
- Queue
- Role

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)
- [AWS CLI lambda reference](https://docs.aws.amazon.com/cli/latest/reference/lambda/index.html)
- [AWS CLI sqs reference](https://docs.aws.amazon.com/cli/latest/reference/sqs/index.html)

