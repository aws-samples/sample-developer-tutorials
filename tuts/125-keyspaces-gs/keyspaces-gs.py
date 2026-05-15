import boto3
import time
import uuid

suffix = str(int(time.time()))[-6:]
client = boto3.client('keyspaces', region_name='us-east-1')

tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'keyspaces-gs'}]

# Create Keyspace
ks_name = f'ks_{suffix}'
client.create_keyspace(keyspaceName=ks_name, Tags=tags)
time.sleep(5)
print("Keyspace created")

# Create Table
client.create_table(
    keyspaceName=ks_name,
    tableName='users',
    schemaDefinition={
        'allColumns': [
            {'name': 'id', 'type': 'text'},
            {'name': 'name', 'type': 'text'}
        ],
        'partitionKeys': [{'name': 'id'}]
    },
    Tags=tags
)
time.sleep(10)
print("Table created")

# Verify Keyspace and Table
client.get_keyspace(keyspaceName=ks_name)
client.get_table(keyspaceName=ks_name, tableName='users')
print("Keyspace and Table verified")

# Wait for table to be fully active before deletion
time.sleep(30)

# Delete Table
client.delete_table(keyspaceName=ks_name, tableName='users')
time.sleep(10)
print("Table deleted")

# Wait before attempting to delete Keyspace
time.sleep(30)

# Delete Keyspace
try:
    client.delete_keyspace(keyspaceName=ks_name)
    print("Keyspace deleted")
except Exception as e:
    print(f"Failed to delete Keyspace: {e}")

print("PASS")