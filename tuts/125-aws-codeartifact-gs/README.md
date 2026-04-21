# Aws Codeartifact Gs

An AWS CLI tutorial that demonstrates Codeartifact operations.

## Running

```bash
bash aws-codeartifact-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash aws-codeartifact-gs.sh
```

## What it does

1. Creating domain: $DOMAIN
2. Creating repository: $REPO
3. Getting authorization token
4. Getting repository endpoint
5. Listing repositories

## Resources created

- Domain
- Repository

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI codeartifact reference](https://docs.aws.amazon.com/cli/latest/reference/codeartifact/index.html)

