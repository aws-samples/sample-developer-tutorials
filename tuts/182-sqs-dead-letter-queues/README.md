# Sqs Dlq

An AWS CLI tutorial that demonstrates Sqs operations.

## Running

```bash
bash sqs-dlq.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash sqs-dlq.sh
```

## What it does

1. Creating DLQ
2. Creating main queue with redrive
3. Sending a message
4. Receiving without deleting (simulating failure)
5. Checking DLQ

## Resources created

- Queue

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI sqs reference](https://docs.aws.amazon.com/cli/latest/reference/sqs/index.html)

