# Amazon Glacier Gs

An AWS CLI tutorial that demonstrates Glacier operations.

## Running

```bash
bash amazon-glacier-gs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash amazon-glacier-gs.sh
```

## What it does

1. Creating vault: $VAULT_NAME
2. Describing vault
3. Uploading an archive
4. Listing vaults
5. Initiating inventory retrieval

## Resources created

- Vault

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI glacier reference](https://docs.aws.amazon.com/cli/latest/reference/glacier/index.html)

