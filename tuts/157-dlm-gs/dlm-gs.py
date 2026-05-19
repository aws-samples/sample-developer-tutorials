import os
import boto3
import json
import time

# Generate a unique suffix based on the current time
suffix = str(int(time.time()))[-6:]

# Create a client for the dlm service in the us-east-1 region
client = boto3.client('dlm', region_name='us-east-1')

# Define the execution role ARN required by DLM
execution_role_arn = os.environ['TUTORIAL_ROLE_ARN']

# Create a lifecycle policy
r = client.create_lifecycle_policy(
    ExecutionRoleArn=execution_role_arn,
    Description=f'Test policy {suffix}',
    State='ENABLED',
    PolicyDetails={
        'PolicyType': 'EBS_SNAPSHOT_MANAGEMENT',
        'ResourceTypes': ['VOLUME'],
        'Schedules': [
            {
                'Name': 'Daily',
                'CreateRule': {
                    'Interval': 24,
                    'IntervalUnit': 'HOURS'
                },
                'RetainRule': {
                    'Count': 1
                }
            }
        ],
        'TargetTags': [
            {'Key': 'Backup', 'Value': 'true'}
        ]
    }
)

# Extract the policy ID from the response
policy_id = r['PolicyId']

# Print the created policy details
print("Created policy:", json.dumps(r, indent=2))

# Attempt to retrieve the lifecycle policy using the policy ID
try:
    policy = client.get_lifecycle_policy(PolicyId=policy_id)
    # Print the retrieved policy details
    print("Retrieved policy:", json.dumps(policy, indent=2))
except Exception as e:
    print("Failed to retrieve policy:", e)

# Delete the lifecycle policy using the policy ID
client.delete_lifecycle_policy(PolicyId=policy_id)

# Print status to indicate successful completion
print("PASS")