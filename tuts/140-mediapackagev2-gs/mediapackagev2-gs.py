import boto3
import json
import time
import uuid

client = boto3.client('mediapackagev2', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
channel_group_name = f'test-channel-group-{suffix}'
client_token = uuid.uuid4().hex[:8]

# Create Channel Group
print("Creating Channel Group...")
response = client.create_channel_group(
    ChannelGroupName=channel_group_name,
    ClientToken=client_token,
    Description="Test Channel Group",
    Tags={"Environment": "Test"}
)
print("Channel Group Created")

# Verify Channel Group Creation
print("Verifying Channel Group Creation...")
response = client.get_channel_group(ChannelGroupName=channel_group_name)
print("Channel Group Verified")

# List Channel Groups
print("Listing Channel Groups...")
response = client.list_channel_groups(MaxResults=10)
print("Channel Groups Listed")

# Delete Channel Group
print("Deleting Channel Group...")
response = client.delete_channel_group(ChannelGroupName=channel_group_name)
print("Channel Group Deleted")

print("PASS")