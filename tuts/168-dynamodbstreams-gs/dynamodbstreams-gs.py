import boto3
import uuid
import time

# Initialize a DynamoDB client
dynamodb = boto3.client('dynamodb')

# Generate a unique suffix
unique_suffix = str(uuid.uuid4())

# Create a table with a unique name and specified tags
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

# Wait until the table is active
while True:
    response = dynamodb.describe_table(TableName=table_name)
    if response['Table']['TableStatus'] == 'ACTIVE':
        break
    time.sleep(5)

print("PASS")

# Delete the table
dynamodb.delete_table(TableName=table_name)
print("Table deletion status: Pending")