#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/ddb-query.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); TABLE="tut-query-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws dynamodb delete-table --table-name "$TABLE" > /dev/null 2>&1 && echo "  Deleted table"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating table with GSI"
aws dynamodb create-table --table-name "$TABLE" --key-schema AttributeName=pk,KeyType=HASH AttributeName=sk,KeyType=RANGE --attribute-definitions AttributeName=pk,AttributeType=S AttributeName=sk,AttributeType=S AttributeName=status,AttributeType=S --billing-mode PAY_PER_REQUEST --global-secondary-indexes '[{"IndexName":"status-index","KeySchema":[{"AttributeName":"status","KeyType":"HASH"},{"AttributeName":"sk","KeyType":"RANGE"}],"Projection":{"ProjectionType":"ALL"}}]' > /dev/null
aws dynamodb wait table-exists --table-name "$TABLE"
echo "Step 2: Writing items"
for i in 1 2 3 4 5; do
    STATUS=$( [ $((i % 2)) -eq 0 ] && echo "active" || echo "inactive" )
    aws dynamodb put-item --table-name "$TABLE" --item "{\"pk\":{\"S\":\"user-$i\"},\"sk\":{\"S\":\"profile\"},\"name\":{\"S\":\"User $i\"},\"status\":{\"S\":\"$STATUS\"}}" 2>/dev/null
done
echo "  Wrote 5 items"
echo "Step 3: Query by partition key"
aws dynamodb query --table-name "$TABLE" --key-condition-expression "pk = :pk" --expression-attribute-values '{":pk":{"S":"user-1"}}' --query 'Items[].{pk:pk.S,name:name.S,status:status.S}' --output table
echo "Step 4: Query GSI (active users)"
aws dynamodb query --table-name "$TABLE" --index-name status-index --key-condition-expression "#s = :s" --expression-attribute-names '{"#s":"status"}' --expression-attribute-values '{":s":{"S":"active"}}' --query 'Items[].{pk:pk.S,name:name.S}' --output table
echo "Step 5: Scan with filter"
aws dynamodb scan --table-name "$TABLE" --filter-expression "#s = :s" --expression-attribute-names '{"#s":"status"}' --expression-attribute-values '{":s":{"S":"inactive"}}' --query '{Count:Count,Items:Items[].{pk:pk.S,name:name.S}}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
