# Lambda Urls

An AWS CLI tutorial that demonstrates Iam operations.

## Running

```bash
bash lambda-urls.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash lambda-urls.sh
```

## What it does

1. Creating function
2. Creating function URL
3. Testing the URL
4. Getting URL config

## Resources created

- Function
- Function Url Config
- Role

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)
- [AWS CLI lambda reference](https://docs.aws.amazon.com/cli/latest/reference/lambda/index.html)

