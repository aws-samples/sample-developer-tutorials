# Aws Fis Gs

An AWS CLI tutorial that demonstrates Fis operations.

## Running

```bash
bash aws-fis-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash aws-fis-gs.sh
```

## What it does

1. Creating IAM role
2. Listing available actions
3. Creating experiment template
4. Describing template
5. Listing templates

## Resources created

- Experiment Template
- Role
- Role Policy

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI fis reference](https://docs.aws.amazon.com/cli/latest/reference/fis/index.html)
- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)

