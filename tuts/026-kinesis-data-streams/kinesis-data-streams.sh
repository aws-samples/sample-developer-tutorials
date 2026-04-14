#!/bin/bash
# Tutorial: Process real-time data with Amazon Kinesis Data Streams
# Source: https://docs.aws.amazon.com/streams/latest/dev/tutorial-stock-data-kplkcl2.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/kinesis-ds-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(openssl rand -hex 4)
STREAM_NAME="stock-stream-${RANDOM_ID}"
ROLE_NAME="kinesis-tut-role-${RANDOM_ID}"
PRODUCER_NAME="stock-producer-${RANDOM_ID}"
CONSUMER_NAME="stock-consumer-${RANDOM_ID}"
TABLE_NAME="stock-trades-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    [ -n "$EVENT_SOURCE_UUID" ] && \
        aws lambda delete-event-source-mapping --uuid "$EVENT_SOURCE_UUID" > /dev/null 2>&1 && echo "  Deleted event source mapping"
    aws lambda delete-function --function-name "$PRODUCER_NAME" 2>/dev/null && echo "  Deleted function $PRODUCER_NAME"
    aws lambda delete-function --function-name "$CONSUMER_NAME" 2>/dev/null && echo "  Deleted function $CONSUMER_NAME"
    aws dynamodb delete-table --table-name "$TABLE_NAME" > /dev/null 2>&1 && echo "  Deleted table $TABLE_NAME"
    aws kinesis delete-stream --stream-name "$STREAM_NAME" 2>/dev/null && echo "  Deleted stream $STREAM_NAME"
    aws iam detach-role-policy --role-name "$ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null
    aws iam detach-role-policy --role-name "$ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess 2>/dev/null
    # Delete inline policy
    aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name kinesis-dynamodb 2>/dev/null
    aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role $ROLE_NAME"
    aws logs delete-log-group --log-group-name "/aws/lambda/$PRODUCER_NAME" 2>/dev/null
    aws logs delete-log-group --log-group-name "/aws/lambda/$CONSUMER_NAME" 2>/dev/null && echo "  Deleted log groups"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create Kinesis data stream
echo "Step 1: Creating Kinesis data stream: $STREAM_NAME"
aws kinesis create-stream --stream-name "$STREAM_NAME" --shard-count 1
echo "  Waiting for stream to become active..."
aws kinesis wait stream-exists --stream-name "$STREAM_NAME"
STREAM_ARN=$(aws kinesis describe-stream-summary --stream-name "$STREAM_NAME" \
    --query 'StreamDescriptionSummary.StreamARN' --output text)
echo "  Stream ARN: $STREAM_ARN"

# Step 2: Create IAM role
echo "Step 2: Creating IAM role: $ROLE_NAME"
ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }' --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam attach-role-policy --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name kinesis-dynamodb \
    --policy-document '{
        "Version":"2012-10-17",
        "Statement":[
            {"Effect":"Allow","Action":["kinesis:PutRecord","kinesis:PutRecords"],"Resource":"*"},
            {"Effect":"Allow","Action":["dynamodb:PutItem","dynamodb:CreateTable","dynamodb:DescribeTable"],"Resource":"*"}
        ]
    }'
echo "  Role ARN: $ROLE_ARN"
echo "  Waiting for role propagation..."
sleep 10

# Step 3: Create producer Lambda function
echo "Step 3: Creating producer function: $PRODUCER_NAME"
cat > "$WORK_DIR/producer.py" << PYEOF
import boto3, json, random, time, os

def lambda_handler(event, context):
    kinesis = boto3.client('kinesis')
    stream = os.environ['STREAM_NAME']
    tickers = ['AAPL', 'AMZN', 'MSFT', 'GOOGL', 'TSLA', 'NFLX', 'NVDA', 'META']
    trades = []
    for _ in range(10):
        ticker = random.choice(tickers)
        trade = {
            'ticker': ticker,
            'type': random.choice(['BUY', 'SELL']),
            'price': round(random.uniform(50, 500), 2),
            'quantity': random.randint(1, 100),
            'timestamp': int(time.time() * 1000)
        }
        kinesis.put_record(StreamName=stream, Data=json.dumps(trade), PartitionKey=ticker)
        trades.append(trade)
    print(f"Produced {len(trades)} trades")
    return {'statusCode': 200, 'body': f'{len(trades)} trades sent'}
PYEOF
(cd "$WORK_DIR" && zip producer.zip producer.py > /dev/null)

aws lambda create-function --function-name "$PRODUCER_NAME" \
    --zip-file "fileb://$WORK_DIR/producer.zip" \
    --handler producer.lambda_handler --runtime python3.12 \
    --role "$ROLE_ARN" --timeout 30 \
    --architectures x86_64 \
    --environment "Variables={STREAM_NAME=$STREAM_NAME}" \
    --query 'FunctionArn' --output text
aws lambda wait function-active-v2 --function-name "$PRODUCER_NAME"

# Step 4: Create consumer Lambda function
echo "Step 4: Creating consumer function: $CONSUMER_NAME"
cat > "$WORK_DIR/consumer.py" << PYEOF
import boto3, json, base64, os, time

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table_name = os.environ['TABLE_NAME']
    table = dynamodb.Table(table_name)
    processed = 0
    for record in event['Records']:
        payload = base64.b64decode(record['kinesis']['data']).decode()
        trade = json.loads(payload)
        table.put_item(Item={
            'TradeId': f"{trade['timestamp']}-{trade['ticker']}",
            'Ticker': trade['ticker'],
            'Type': trade['type'],
            'Price': str(trade['price']),
            'Quantity': trade['quantity'],
            'Timestamp': trade['timestamp']
        })
        processed += 1
    print(f"Processed {processed} trades")
    return {'statusCode': 200}
PYEOF
(cd "$WORK_DIR" && zip consumer.zip consumer.py > /dev/null)

aws lambda create-function --function-name "$CONSUMER_NAME" \
    --zip-file "fileb://$WORK_DIR/consumer.zip" \
    --handler consumer.lambda_handler --runtime python3.12 \
    --role "$ROLE_ARN" --timeout 30 \
    --architectures x86_64 \
    --environment "Variables={TABLE_NAME=$TABLE_NAME}" \
    --query 'FunctionArn' --output text
aws lambda wait function-active-v2 --function-name "$CONSUMER_NAME"

# Step 5: Create DynamoDB table
echo "Step 5: Creating DynamoDB table: $TABLE_NAME"
aws dynamodb create-table --table-name "$TABLE_NAME" \
    --key-schema AttributeName=TradeId,KeyType=HASH \
    --attribute-definitions AttributeName=TradeId,AttributeType=S \
    --billing-mode PAY_PER_REQUEST \
    --query 'TableDescription.TableArn' --output text
aws dynamodb wait table-exists --table-name "$TABLE_NAME"
echo "  Table active"

# Step 6: Connect Kinesis stream to consumer Lambda
echo "Step 6: Creating event source mapping (stream → consumer)"
EVENT_SOURCE_UUID=$(aws lambda create-event-source-mapping \
    --function-name "$CONSUMER_NAME" \
    --event-source-arn "$STREAM_ARN" \
    --batch-size 100 \
    --starting-position LATEST \
    --query 'UUID' --output text)
echo "  Event source mapping: $EVENT_SOURCE_UUID"
echo "  Waiting for mapping to become active..."
for i in $(seq 1 20); do
    STATE=$(aws lambda get-event-source-mapping --uuid "$EVENT_SOURCE_UUID" \
        --query 'State' --output text 2>/dev/null || true)
    [ "$STATE" = "Enabled" ] && break
    sleep 5
done
echo "  State: $STATE"

# Step 7: Produce stock trades
echo "Step 7: Producing stock trades"
aws lambda invoke --function-name "$PRODUCER_NAME" \
    --cli-binary-format raw-in-base64-out \
    "$WORK_DIR/producer-response.json" > /dev/null
echo "  $(cat "$WORK_DIR/producer-response.json")"

# Step 8: Verify trades in DynamoDB
echo "Step 8: Verifying trades in DynamoDB (waiting for consumer to process)..."
sleep 10
FOUND_TRADES=false
for i in $(seq 1 18); do
    COUNT=$(aws dynamodb scan --table-name "$TABLE_NAME" --select COUNT \
        --query 'Count' --output text 2>/dev/null || echo "0")
    if [ "$COUNT" -gt 0 ] 2>/dev/null; then
        echo "  Found $COUNT trades in DynamoDB"
        aws dynamodb scan --table-name "$TABLE_NAME" --limit 3 \
            --query 'Items[].{Ticker:Ticker.S,Type:Type.S,Price:Price.S}' --output table
        FOUND_TRADES=true
        break
    fi
    sleep 5
done
if [ "$FOUND_TRADES" = false ]; then
    echo "  Trades not yet visible (Kinesis consumer polling can take up to 60s)"
fi

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Resources left running. Manual cleanup commands:"
    echo "  aws lambda delete-event-source-mapping --uuid $EVENT_SOURCE_UUID"
    echo "  aws lambda delete-function --function-name $PRODUCER_NAME"
    echo "  aws lambda delete-function --function-name $CONSUMER_NAME"
    echo "  aws dynamodb delete-table --table-name $TABLE_NAME"
    echo "  aws kinesis delete-stream --stream-name $STREAM_NAME"
    echo "  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    echo "  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess"
    echo "  aws iam delete-role-policy --role-name $ROLE_NAME --policy-name kinesis-dynamodb"
    echo "  aws iam delete-role --role-name $ROLE_NAME"
fi
