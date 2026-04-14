#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); T="tut-batch-${RANDOM_ID}"
cleanup() { aws dynamodb delete-table --table-name "$T" > /dev/null 2>&1; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating table"; aws dynamodb create-table --table-name "$T" --key-schema AttributeName=pk,KeyType=HASH --attribute-definitions AttributeName=pk,AttributeType=S --billing-mode PAY_PER_REQUEST > /dev/null; aws dynamodb wait table-exists --table-name "$T"
echo "Step 2: Batch write (25 items)"; aws dynamodb batch-write-item --request-items "{\"$T\":[$(for i in $(seq 1 25); do echo -n "{\"PutRequest\":{\"Item\":{\"pk\":{\"S\":\"item-$i\"},\"data\":{\"S\":\"value-$i\"}}}}"; [ $i -lt 25 ] && echo -n ","; done)]}" > /dev/null
echo "  Wrote 25 items"
echo "Step 3: Batch get (5 items)"; aws dynamodb batch-get-item --request-items "{\"$T\":{\"Keys\":[{\"pk\":{\"S\":\"item-1\"}},{\"pk\":{\"S\":\"item-5\"}},{\"pk\":{\"S\":\"item-10\"}},{\"pk\":{\"S\":\"item-15\"}},{\"pk\":{\"S\":\"item-20\"}}]}}" --query "Responses.\"$T\"[].{pk:pk.S,data:data.S}" --output table
echo "Step 4: Scan count"; aws dynamodb scan --table-name "$T" --select COUNT --query 'Count' --output text
echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && cleanup
