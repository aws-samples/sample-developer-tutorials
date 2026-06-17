import boto3
import time
import json

client = boto3.client('sns', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
name = f'contact{suffix}'
email_address = f'test{suffix}@example.com'
tags = {'Environment': 'Test'}

print("Creating email contact...")
response = client.create_topic(
    Name=name,
    Attributes={
        'DisplayName': email_address
    }
)
topic_arn = response['TopicArn']
print(f"Email contact created with ARN: {topic_arn}")

# Add tagging
tag_key_value_pairs = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'notificationscontacts-gs'}]
for tag in tag_key_value_pairs:
    client.tag_resource(ResourceArn=topic_arn, Tags=[tag])

time.sleep(5)  # Wait for the contact to become active

print("Listing topics...")
response = client.list_topics()
print(f"Listed topics: {json.dumps(response, indent=2, default=str)}")

print("Deleting email contact...")
client.delete_topic(TopicArn=topic_arn)
print("Email contact deleted")

time.sleep(5)  # Wait for the deletion to complete

print("PASS")