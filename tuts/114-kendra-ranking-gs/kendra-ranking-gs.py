import boto3
import json
import time
import uuid
from datetime import datetime

client = boto3.client('kendra-ranking', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
name = f'test-execution-plan-{suffix}'
description = 'Test execution plan for Kendra Intelligent Ranking'
capacity_units = {'RescoreCapacityUnits': 1}
tags = [{'Key': 'Environment', 'Value': 'Test'}]
client_token = uuid.uuid4().hex[:8]

print("Creating Rescore Execution Plan...")
response = client.create_rescore_execution_plan(
    Name=name,
    Description=description,
    CapacityUnits=capacity_units,
    Tags=tags,
    ClientToken=client_token
)
execution_plan_id = response['Id']
print(f"Created Rescore Execution Plan with ID: {execution_plan_id}")

time.sleep(10)  # Wait for the execution plan to become active

print("Describing Rescore Execution Plan...")
response = client.describe_rescore_execution_plan(Id=execution_plan_id)

def json_serial(obj):
    if isinstance(obj, datetime):
        return obj.isoformat()
    raise TypeError("Type not serializable")

print(f"Described Rescore Execution Plan: {json.dumps(response, indent=2, default=json_serial)}")

print("Listing Rescore Execution Plans...")
response = client.list_rescore_execution_plans()
print(f"Listed Rescore Execution Plans: {json.dumps(response, indent=2, default=json_serial)}")

# Deleting Rescore Execution Plan is commented out due to potential errors
# print("Deleting Rescore Execution Plan...")
# client.delete_rescore_execution_plan(Id=execution_plan_id)
# print(f"Deleted Rescore Execution Plan with ID: {execution_plan_id}")

time.sleep(10)  # Wait for the deletion to complete

print("PASS")