# Lambda Env Vars

An AWS CLI tutorial that demonstrates Iam operations.

## Running

```bash
bash lambda-env-vars.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash lambda-env-vars.sh
```

## What it does

1. Creating function with environment variables
2. Invoking function
3. Updating environment variables
4. Invoking with updated vars

## Resources created

- Function
- Role

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)
- [AWS CLI lambda reference](https://docs.aws.amazon.com/cli/latest/reference/lambda/index.html)

