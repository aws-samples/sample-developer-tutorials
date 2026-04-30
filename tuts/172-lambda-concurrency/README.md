# Lambda Concurrency

An AWS CLI tutorial that demonstrates Iam operations.

## Running

```bash
bash lambda-concurrency.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash lambda-concurrency.sh
```

## What it does

1. Getting account concurrency limits
2. Setting reserved concurrency
3. Getting function concurrency
4. Removing reserved concurrency

## Resources created

- Function
- Role
- Function Concurrency

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)
- [AWS CLI lambda reference](https://docs.aws.amazon.com/cli/latest/reference/lambda/index.html)

