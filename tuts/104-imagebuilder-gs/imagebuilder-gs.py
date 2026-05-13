import boto3
import time
import uuid

# Initialize the Image Builder client
client = boto3.client('imagebuilder', region_name='us-east-1')

# Generate a unique suffix for component names
suffix = str(int(time.time()))[-6:]

# List components
print("Listing components before creation...")
list_response = client.list_components(owner='Self', maxResults=10)
print(f"Listed components: {list_response}")

print("PASS")