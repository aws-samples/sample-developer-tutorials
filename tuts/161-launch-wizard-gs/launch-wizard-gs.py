import boto3
import json
import time

suffix = str(int(time.time()))[-6:]
client = boto3.client('launch-wizard', region_name='us-east-1')

# List existing deployments
deployments = client.list_deployments()
print(f"Existing Deployments: {len(deployments.get('deployments', []))}")

# Check if there are any deployments to list events for
if deployments.get('deployments'):
    deployment_id = deployments['deployments'][0]['id']
    events = client.list_deployment_events(deploymentId=deployment_id)
    print(f"Events for Deployment {deployment_id}: {len(events.get('deploymentEvents', []))}")
else:
    print("No deployments available to list events for.")

# Example of creating a deployment (uncomment and modify as needed)
response = client.create_deployment(
    workloadName='example-workload',
    deploymentPatternName='example-pattern',
    name=f'example-deployment-{suffix}',
    specifications=json.dumps({
        'key1': 'value1',
        'key2': 'value2'
    }),
    tags=[{'Key':'project','Value':'doc-smith'},{'Key':'tutorial','Value':'launch-wizard-gs'}]
)
print(f"Created Deployment: {response['id']}")

# Tagging the created resource if the create_deployment API doesn't support Tags parameter directly
client.tag_resource(
    resourceArn=response['arn'],
    tags=[
        {'Key': 'project', 'Value': 'doc-smith'},
        {'Key': 'tutorial', 'Value': 'launch-wizard-gs'}
    ]
)

print("PASS")
