# Lambda Layers

An AWS CLI tutorial that demonstrates Iam operations.

## Running

```bash
bash lambda-layers.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash lambda-layers.sh
```

## What it does

1. Creating a layer
2. Creating function that uses the layer
3. Invoking function
4. Listing layers

## Resources created

- Function
- Role

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)
- [AWS CLI lambda reference](https://docs.aws.amazon.com/cli/latest/reference/lambda/index.html)

