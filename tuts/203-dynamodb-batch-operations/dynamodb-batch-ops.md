# Dynamodb Batch Ops

## Prerequisites

1. AWS CLI installed and configured (`aws configure`)
2. Appropriate IAM permissions for the AWS services used

## Step 1: Creating table"; aws dynamodb create-table --table-name "$T" --key-schema AttributeName=pk,KeyType=HASH --attribute-definitions AttributeName=pk,AttributeType=S --billing-mode PAY_PER_REQUEST > /dev/null; aws dynamodb wait table-exists --table-name "$T

The script handles this step automatically. See `dynamodb-batch-ops.sh` for the exact CLI commands.

## Step 2: Batch write (25 items)"; aws dynamodb batch-write-item --request-items "{\"$T\":[$(for i in $(seq 1 25); do echo -n "{\"PutRequest\":{\"Item\":{\"pk\":{\"S\":\"item-$i\"},\"data\":{\"S\":\"value-$i\"}}}}"; [ $i -lt 25 ] && echo -n ","; done)]}

The script handles this step automatically. See `dynamodb-batch-ops.sh` for the exact CLI commands.

## Step 3: Batch get (5 items)"; aws dynamodb batch-get-item --request-items "{\"$T\":{\"Keys\":[{\"pk\":{\"S\":\"item-1\"}},{\"pk\":{\"S\":\"item-5\"}},{\"pk\":{\"S\":\"item-10\"}},{\"pk\":{\"S\":\"item-15\"}},{\"pk\":{\"S\":\"item-20\"}}]}}" --query "Responses.\"$T\"[].{pk:pk.S,data:data.S}

The script handles this step automatically. See `dynamodb-batch-ops.sh` for the exact CLI commands.

## Step 4: Scan count"; aws dynamodb scan --table-name "$T

The script handles this step automatically. See `dynamodb-batch-ops.sh` for the exact CLI commands.

## Cleanup

The script prompts you to clean up all created resources. If you need to clean up manually, check the script log for the resource names that were created.

