# Dynamodb Batch Ops

An AWS CLI tutorial that demonstrates Dynamodb operations.

## Running

```bash
bash dynamodb-batch-ops.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash dynamodb-batch-ops.sh
```

## What it does

1. Creating table"; aws dynamodb create-table --table-name "$T" --key-schema AttributeName=pk,KeyType=HASH --attribute-definitions AttributeName=pk,AttributeType=S --billing-mode PAY_PER_REQUEST > /dev/null; aws dynamodb wait table-exists --table-name "$T
2. Batch write (25 items)"; aws dynamodb batch-write-item --request-items "{\"$T\":[$(for i in $(seq 1 25); do echo -n "{\"PutRequest\":{\"Item\":{\"pk\":{\"S\":\"item-$i\"},\"data\":{\"S\":\"value-$i\"}}}}"; [ $i -lt 25 ] && echo -n ","; done)]}
3. Batch get (5 items)"; aws dynamodb batch-get-item --request-items "{\"$T\":{\"Keys\":[{\"pk\":{\"S\":\"item-1\"}},{\"pk\":{\"S\":\"item-5\"}},{\"pk\":{\"S\":\"item-10\"}},{\"pk\":{\"S\":\"item-15\"}},{\"pk\":{\"S\":\"item-20\"}}]}}" --query "Responses.\"$T\"[].{pk:pk.S,data:data.S}
4. Scan count"; aws dynamodb scan --table-name "$T

## Resources created

- Table

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI dynamodb reference](https://docs.aws.amazon.com/cli/latest/reference/dynamodb/index.html)

