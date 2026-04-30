# Dynamodb Queries

An AWS CLI tutorial that demonstrates Dynamodb operations.

## Running

```bash
bash dynamodb-queries.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash dynamodb-queries.sh
```

## What it does

1. Creating table with GSI
2. Writing items
3. Query by partition key
4. Query GSI (active users)
5. Scan with filter

## Resources created

- Table
- Item

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI dynamodb reference](https://docs.aws.amazon.com/cli/latest/reference/dynamodb/index.html)

