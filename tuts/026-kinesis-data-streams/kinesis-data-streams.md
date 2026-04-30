# Process real-time data with Amazon Kinesis Data Streams

This tutorial shows you how to process real-time stock trade data using Amazon Kinesis Data Streams. You create a data stream, set up a Lambda producer to generate trades, connect a Lambda consumer to process them, and store results in DynamoDB.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions to create Kinesis streams, Lambda functions, IAM roles, and DynamoDB tables

## Step 1: Create a Kinesis data stream

```bash
aws kinesis create-stream --stream-name stock-stream --shard-count 1
aws kinesis wait stream-exists --stream-name stock-stream
```

## Step 2: Create an execution role

Create a role with permissions for Lambda, Kinesis, and DynamoDB:

```bash
aws iam create-role --role-name kinesis-tutorial-role \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }'

aws iam attach-role-policy --role-name kinesis-tutorial-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam attach-role-policy --role-name kinesis-tutorial-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess
```

Add an inline policy for Kinesis writes and DynamoDB access:

```bash
aws iam put-role-policy --role-name kinesis-tutorial-role --policy-name kinesis-dynamodb \
    --policy-document '{
        "Version":"2012-10-17",
        "Statement":[
            {"Effect":"Allow","Action":["kinesis:PutRecord","kinesis:PutRecords"],"Resource":"*"},
            {"Effect":"Allow","Action":["dynamodb:PutItem","dynamodb:CreateTable","dynamodb:DescribeTable"],"Resource":"*"}
        ]
    }'
```

## Step 3: Create the producer function

The producer generates random stock trades and writes them to the Kinesis stream.

```python
# producer.py
import boto3, json, random, time, os

def lambda_handler(event, context):
    kinesis = boto3.client('kinesis')
    stream = os.environ['STREAM_NAME']
    tickers = ['AAPL', 'AMZN', 'MSFT', 'GOOGL', 'TSLA', 'NFLX', 'NVDA', 'META']
    for _ in range(10):
        ticker = random.choice(tickers)
        trade = {'ticker': ticker, 'type': random.choice(['BUY', 'SELL']),
                 'price': round(random.uniform(50, 500), 2),
                 'quantity': random.randint(1, 100),
                 'timestamp': int(time.time() * 1000)}
        kinesis.put_record(StreamName=stream, Data=json.dumps(trade), PartitionKey=ticker)
    return {'statusCode': 200, 'body': '10 trades sent'}
```

Deploy:

```bash
zip producer.zip producer.py
aws lambda create-function --function-name stock-producer \
    --zip-file fileb://producer.zip --handler producer.lambda_handler \
    --runtime python3.12 --role <role-arn> \
    --environment Variables={STREAM_NAME=stock-stream}
```

## Step 4: Create the consumer function

The consumer reads trades from the stream and stores them in DynamoDB.

```python
# consumer.py
import boto3, json, base64, os

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['TABLE_NAME'])
    for record in event['Records']:
        payload = base64.b64decode(record['kinesis']['data']).decode()
        trade = json.loads(payload)
        table.put_item(Item={
            'TradeId': f"{trade['timestamp']}-{trade['ticker']}",
            'Ticker': trade['ticker'], 'Type': trade['type'],
            'Price': str(trade['price']), 'Quantity': trade['quantity']})
    return {'statusCode': 200}
```

## Step 5: Create a DynamoDB table

```bash
aws dynamodb create-table --table-name stock-trades \
    --key-schema AttributeName=TradeId,KeyType=HASH \
    --attribute-definitions AttributeName=TradeId,AttributeType=S \
    --billing-mode PAY_PER_REQUEST
aws dynamodb wait table-exists --table-name stock-trades
```

## Step 6: Connect the stream to the consumer

```bash
aws lambda create-event-source-mapping \
    --function-name stock-consumer \
    --event-source-arn <stream-arn> \
    --batch-size 100 --starting-position LATEST
```

## Step 7: Produce trades and verify

Invoke the producer, then check DynamoDB:

```bash
aws lambda invoke --function-name stock-producer response.json
aws dynamodb scan --table-name stock-trades --limit 3 \
    --query 'Items[].{Ticker:Ticker.S,Type:Type.S,Price:Price.S}' --output table
```

## Cleanup

```bash
aws lambda delete-event-source-mapping --uuid <mapping-uuid>
aws lambda delete-function --function-name stock-producer
aws lambda delete-function --function-name stock-consumer
aws dynamodb delete-table --table-name stock-trades
aws kinesis delete-stream --stream-name stock-stream
aws iam detach-role-policy --role-name kinesis-tutorial-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam detach-role-policy --role-name kinesis-tutorial-role --policy-arn arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess
aws iam delete-role-policy --role-name kinesis-tutorial-role --policy-name kinesis-dynamodb
aws iam delete-role --role-name kinesis-tutorial-role
```

The script automates all steps including cleanup. Run it with:

```bash
bash kinesis-data-streams.sh
```
