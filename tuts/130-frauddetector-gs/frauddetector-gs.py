import boto3
import json
import time
import uuid
import random

client = boto3.client('frauddetector', region_name='us-east-1')
suffix = ''.join(random.choices('abcdefghijklmnopqrstuvwxyz0123456789', k=6))
variable_name = f'var_{suffix}'
detector_id = f'det_{suffix}'

# Create a fraud detection variable
create_variable_response = client.create_variable(
    name=variable_name,
    dataType='STRING',
    dataSource='EVENT',
    defaultValue='UNKNOWN',
    description='Test variable for fraud detection',
    tags=[{'key': 'test', 'value': 'true'}]
)
print("Variable created:", json.dumps(create_variable_response, indent=2))

# Clean up
delete_variable_response = client.delete_variable(name=variable_name)
print("Variable deleted:", json.dumps(delete_variable_response, indent=2))

print("PASS")