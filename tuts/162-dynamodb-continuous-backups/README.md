# Dynamodb Global Tables

An AWS CLI tutorial that demonstrates Dynamodb operations.

## Running

```bash
bash dynamodb-global-tables.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash dynamodb-global-tables.sh
```

## What it does

1. Creating table
2. Enabling point-in-time recovery
3. Describing continuous backups
4. Writing and reading items
5. Table details

## Resources created

- Table
- Item

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI dynamodb reference](https://docs.aws.amazon.com/cli/latest/reference/dynamodb/index.html)

