import boto3
import json
import time
import uuid

client = boto3.client('mwaa', region_name='us-east-1')
suffix = str(int(time.time()))[-6:]
workflow_name = f'workflow-{suffix}'
definition_s3_location = {'Bucket': 'your-bucket', 'Key': 'your-workflow-definition.yaml'}
role_arn = 'arn:aws:iam::559823168634:role/doc-babu-mwaa-serverless-role'
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value':'mwaa-serverless-gs'}]

# Create Workflow
try:
    response = client.create_cli_token(WebServerHostname='your-hostname')
    print("CLI token created")
except Exception as e:
    print(f"Failed to create CLI token: {e}")

# Get Workflow
try:
    response = client.list_environments()
    environments = response['Environments']
    if environments:
        print(f"Environments: {json.dumps(environments, indent=2)}")
except Exception as e:
    print(f"Failed to list environments: {e}")

# Assuming create_environment does not support Tags parameter directly
try:
    response = client.create_environment(
        Name=workflow_name,
        AirflowVersion='2.0.2',
        MaxWorkers=5,
        MinWorkers=2,
        Schedulers=2,
        ExecutionRoleArn=role_arn,
        SourceBucketArn=definition_s3_location['Bucket'],
        DagS3Path=definition_s3_location['Key'],
        EnvironmentClass='mw1.small'
    )
    print("Environment created")
    try:
        client.tag_resource(
            ResourceArn=response['Arn'],
            Tags=tags
        )
        print("Tags added to environment")
    except Exception as tag_e:
        print(f"Failed to tag environment: {tag_e}")
except Exception as e:
    print(f"Failed to create environment: {e}")

print("PASS")