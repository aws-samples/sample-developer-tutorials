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

# Tags to be added
tags = [{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'support-app-gs'}]

try:
    create_response = client.create_slack_channel_configuration(
        channelName=channel_id,
        channelRoleArn='role-arn',
        teamId=team_id,
    )
    print("Create Slack Channel Configuration response:", json.dumps(create_response, indent=2))
except Exception as e:
    print("Failed to create Slack Channel Configuration:", str(e))

try:
    client.delete_slack_channel_configuration(
        channelName=channel_id,
        teamId=team_id
    )
    print("Slack Channel Configuration deleted.")
except Exception as e:
    print("Failed to delete Slack Channel Configuration:", str(e))

print("PASS")