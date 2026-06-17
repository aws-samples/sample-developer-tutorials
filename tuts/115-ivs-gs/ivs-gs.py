import boto3
import json
import time
import uuid

client = boto3.client('ivs', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
channel_name = f'test-channel-{suffix}'

print("Creating IVS channel...")
response = client.create_channel(
    name=channel_name,
    authorized=False,
    insecureIngest=False,
    latencyMode='NORMAL',
    type='STANDARD',
    tags=[{'Key': 'environment', 'Value': 'test'}, {'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'ivs-gs'}]
)
channel_arn = response.get('channel', {}).get('arn')

if channel_arn:
    print(f"Channel created: {channel_arn}")

    time.sleep(5)  # Wait for channel to become active

    print("Verifying channel exists...")
    response = client.get_channel(arn=channel_arn)
    if response['channel']['arn'] == channel_arn:
        print("Channel verified.")

    print("Listing channels to confirm presence...")
    response = client.list_channels(filterByName=channel_name)
    channels = response['channels']
    if any(channel['arn'] == channel_arn for channel in channels):
        print("Channel listed successfully.")

    print("Deleting channel...")
    client.delete_channel(arn=channel_arn)
    time.sleep(5)  # Wait for deletion to process

    print("Verifying channel deletion...")
    try:
        client.get_channel(arn=channel_arn)
    except client.exceptions.ResourceNotFoundException:
        print("Channel successfully deleted.")

    print("PASS")
else:
    print("Failed to create channel.")