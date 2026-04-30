# Lambda Aliases

An AWS CLI tutorial that demonstrates Iam operations.

## Running

```bash
bash lambda-aliases.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash lambda-aliases.sh
```

## What it does

1. Creating function (v1)
2. Creating alias pointing to v1
3. Deploying v2 with canary
4. Invoking via alias (multiple times)
5. Shifting all traffic to v2

## Resources created

- Alias
- Function
- Role

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)
- [AWS CLI lambda reference](https://docs.aws.amazon.com/cli/latest/reference/lambda/index.html)

