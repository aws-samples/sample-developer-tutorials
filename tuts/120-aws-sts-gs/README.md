# Aws Sts Gs

An AWS CLI tutorial that demonstrates Iam operations.

## Running

```bash
bash aws-sts-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash aws-sts-gs.sh
```

## What it does

1. Getting caller identity
2. Creating a role to assume
3. Assuming the role
4. Using temporary credentials
5. Session tags (decode token)

## Resources created

- Role
- Role Policy

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)

