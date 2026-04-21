# Ses Identity

An AWS CLI tutorial that demonstrates Sesv2 operations.

## Running

```bash
bash ses-identity.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash ses-identity.sh
```

## What it does

1. Creating email identity (domain): $DOMAIN
2. Getting DKIM tokens
3. Getting sending quota
4. Listing identities

## Resources created

- Email Identity

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI sesv2 reference](https://docs.aws.amazon.com/cli/latest/reference/sesv2/index.html)

