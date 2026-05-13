import boto3
import json
import time
import uuid

client = boto3.client('wisdom', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
name = f'test-assistant-{suffix}'
client_token = uuid.uuid4().hex[:8]

print("Creating assistant...")
response = client.create_assistant(
    name=name,
    type='AGENT',
    clientToken=client_token,
    description='Test assistant for demonstration'
)

assistant_id = response['assistant']['assistantId']
print(f"Assistant created with ID: {assistant_id}")

time.sleep(10)  # Wait for the assistant to become active

print("Verifying assistant exists...")
response = client.get_assistant(assistantId=assistant_id)
if response['assistant']['name'] == name:
    print("Assistant verified.")

print("Listing assistants...")
response = client.list_assistants()
assistants = response['assistantSummaries']
found = any(assistant['name'] == name for assistant in assistants)
if found:
    print("Assistant found in list.")

print("Deleting assistant...")
client.delete_assistant(assistantId=assistant_id)
time.sleep(10)  # Wait for the deletion to complete

try:
    client.get_assistant(assistantId=assistant_id)
except client.exceptions.ResourceNotFoundException:
    print("Assistant successfully deleted.")
    print("PASS")