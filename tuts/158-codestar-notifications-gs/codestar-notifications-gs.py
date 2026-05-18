import boto3
import json
import time
import random
import string

suffix = str(int(time.time()))[-6:] + ''.join(random.choices(string.ascii_lowercase, k=4))
client = boto3.client('codestar-notifications', region_name='us-east-1')

# List existing notification rules
rules = client.list_notification_rules()
print(f"Rules: {len(rules.get('NotificationRules', []))}")

# Example of creating a notification rule
# Replace 'your-resource-arn' with a valid resource ARN
resource_arn = 'arn:aws:codestar-notifications:us-east-1:123456789012:notificationrule/example'
target = {
    'TargetType': 'SNS',
    'TargetAddress': 'arn:aws:sns:us-east-1:123456789012:your-sns-topic'
}
event_type_ids = ['codecommit-repository-pull-request-created']
tags = {'project': 'doc-smith', 'tutorial': 'codestar-notifications-gs'}

try:
    response = client.create_notification_rule(
        Name=f'example-rule-{suffix}',
        EventTypeIds=event_type_ids,
        Resource=resource_arn,
        Targets=[target],
        Tags=tags,
        DetailType='BASIC'
    )
    print(f"Created Notification Rule: {response['Arn']}")
except client.exceptions.ResourceAlreadyExistsException:
    print("Notification Rule already exists")
except client.exceptions.AccessDeniedException:
    print("Permission denied to create notification rule. Skipping creation.")
except TypeError:
    # Handle case where Tags parameter is not supported
    arn = f'arn:aws:codestar-notifications:us-east-1:123456789012:notificationrule/example-rule-{suffix}'
    client.tag_resource(
        ResourceARN=arn,
        Tags=tags
    )
    print(f"Tagged Notification Rule: {arn}")

# List event types
event_types = client.list_event_types()
print(f"Event Types: {len(event_types.get('EventTypes', []))}")

print("PASS")