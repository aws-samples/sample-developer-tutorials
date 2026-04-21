# Sns Filtering

An AWS CLI tutorial that demonstrates Sns operations.

## Running

```bash
bash sns-filtering.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash sns-filtering.sh
```

## What it does

1. Creating topic and queues
2. Subscribing with filters
3. Publishing messages
4. Checking queues

## Resources created

- Queue
- Topic

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI sns reference](https://docs.aws.amazon.com/cli/latest/reference/sns/index.html)
- [AWS CLI sqs reference](https://docs.aws.amazon.com/cli/latest/reference/sqs/index.html)

