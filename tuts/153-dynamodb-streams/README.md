# Dynamodb Streams

An AWS CLI tutorial that demonstrates Dynamodb operations.

## Running

```bash
bash dynamodb-streams.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash dynamodb-streams.sh
```

## What it does

1. Creating table with streams enabled
2. Writing items to trigger stream events
3. Reading stream records

## Resources created

- Table
- Item

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI dynamodb reference](https://docs.aws.amazon.com/cli/latest/reference/dynamodb/index.html)
- [AWS CLI dynamodbstreams reference](https://docs.aws.amazon.com/cli/latest/reference/dynamodbstreams/index.html)

