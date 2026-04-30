# Ec2 Keypairs

An AWS CLI tutorial that demonstrates Ec2 operations.

## Running

```bash
bash ec2-keypairs.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash ec2-keypairs.sh
```

## What it does

1. Creating RSA key pair
2. Creating ED25519 key pair
3. Describing key pairs
4. Listing all tutorial key pairs

## Resources created

- Key Pair

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI ec2 reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html)

