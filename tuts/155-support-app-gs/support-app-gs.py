import boto3
import json
import time
import random
import string

# Initialize the client
client = boto3.client('support-app', region_name='us-east-1')

# Generate a suffix based on the current time and random characters
suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=12))

# Unique identifiers for the tutorial
channel_id = f'channel-{suffix}'
team_id = f'team-{suffix}'

print("Listing Slack Channel Configurations...")
list_channels_response = client.list_slack_channel_configurations()
print("List Slack Channel Configurations response:", json.dumps(list_channels_response, indent=2))

print("PASS")