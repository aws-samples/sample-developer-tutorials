# Dynamodb Ttl

An AWS CLI tutorial that demonstrates Dynamodb operations.

## Running

```bash
bash dynamodb-ttl.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash dynamodb-ttl.sh
```

## What it does

1. Creating table
2. Enabling TTL
3. Writing items with TTL
4. Describing TTL
5. Scanning items

## Resources created

- Table
- Item

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI dynamodb reference](https://docs.aws.amazon.com/cli/latest/reference/dynamodb/index.html)

