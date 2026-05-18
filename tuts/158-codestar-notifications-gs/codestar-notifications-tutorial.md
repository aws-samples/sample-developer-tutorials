# Tutorial: Getting Started with AWS CodeStar Notifications

## Prerequisites

- An AWS account.
- AWS CLI installed and configured.
- Python installed with `boto3` library.

## Steps

### 1. Set up your environment

**Install boto3**

```bash
$ pip install boto3
```

### 2. List existing notification rules

**List rules**

```python
import boto3
import time
import random
import string

suffix = str(int(time.time()))[-6:] + ''.join(random.choices(string.ascii_lowercase, k=4))
client = boto3.client('codestar-notifications', region_name='us-east-1')

rules = client.list_notification_rules()
print(f"Rules: {len(rules.get('NotificationRules', []))}")
```

### 3. Create a notification rule

**Create rule**

```python
resource_arn = 'arn:aws:codestar-notifications:us-east-1:123456789012:notificationrule/example'
target = {
    'TargetType': 'SNS',
    'TargetAddress': 'arn:aws:sns:us-east-1:123456789012:your-sns-topic'
}
event_type_ids = ['codecommit-repository-pull-request-created']

try:
    response = client.create_notification_rule(
        Name=f'example-rule-{suffix}',
        EventTypeIds=event_type_ids,
        Resource=resource_arn,
        Targets=[target],
        Tags={'project': 'doc-smith', 'tutorial': 'codestar-notifications-gs'},
        DetailType='BASIC'
    )
    print(f"Created Notification Rule: {response['Arn']}")
except client.exceptions.ResourceAlreadyExistsException:
    print("Notification Rule already exists")
except client.exceptions.AccessDeniedException:
    print("Permission denied to create notification rule. Skipping creation.")
```

### 4. List event types

**List event types**

```python
event_types = client.list_event_types()
print(f"Event Types: {len(event_types.get('EventTypes', []))}")
```

## Clean up

Delete the created notification rule to avoid unnecessary charges.

**Delete rule**

```python
rule_arn = 'arn:aws:codestar-notifications:us-east-1:123456789012:notificationrule/example-rule-abcdef'
client.delete_notification_rule(Arn=rule_arn)
```

## Next steps

- Explore more event types and targets.
- Integrate with other AWS services for advanced notifications.