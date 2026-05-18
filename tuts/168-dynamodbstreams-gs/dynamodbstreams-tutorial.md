# Tutorial: Create and delete an amazon dynamodb table

This tutorial guides you through creating and deleting an amazon dynamodb table using the boto3 python library.

## Prerequisites

- An aws account.
- Aws credentials configured for boto3.
- Python installed with boto3 library.

## Steps

**1. Initialize a dynamodb client**

```python
import boto3

dynamodb = boto3.client('dynamodb')
```

**2. Generate a unique suffix**

```python
import uuid

unique_suffix = str(uuid.uuid4())
```

**3. Create a table with a unique name and specified tags**

```python
table_name = f'example-table-{unique_suffix}'
response = dynamodb.create_table(
    TableName=table_name,
    KeySchema=[
        {
            'AttributeName': 'id',
            'KeyType': 'HASH'
        },
    ],
    AttributeDefinitions=[
        {
            'AttributeName': 'id',
            'AttributeType': 'S'
        },
    ],
    ProvisionedThroughput={
        'ReadCapacityUnits': 5,
        'WriteCapacityUnits': 5
    },
    Tags=[
        {'Key': 'project', 'Value': 'doc-smith'},
        {'Key': 'tutorial', 'Value': 'dynamodbstreams-gs'}
    ]
)
print("Table creation status:", response['TableDescription']['TableStatus'])
```

**4. Wait until the table is active**

```python
import time

while True:
    response = dynamodb.describe_table(TableName=table_name)
    if response['Table']['TableStatus'] == 'ACTIVE':
        break
    time.sleep(5)

print("PASS")
```

## Clean up

**Delete the table**

```python
dynamodb.delete_table(TableName=table_name)
print("Table deletion status: Pending")
```

## Next steps

- Explore dynamodb features like streams and global tables.
- Learn about dynamodb auto scaling.
- Check out the [aws dynamodb documentation](https://docs.aws.amazon.com/dynamodb/latest/developerguide/Introduction.html) for more information.