import boto3
import time

import os, sys
ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN') or (sys.argv[1] if len(sys.argv) > 1 else None)
if not ROLE_ARN:
    print('Usage: python3 script.py <role-arn>')
    print('Or set TUTORIAL_ROLE_ARN environment variable')
    print('Create the role with: aws cloudformation deploy --template-file prereqs.yaml --stack-name tutorial-prereqs --capabilities CAPABILITY_NAMED_IAM')
    sys.exit(1)

suffix = str(int(time.time()))[-6:]

client = boto3.client('codebuild', region_name='us-east-1')

print("Creating project...")
r = client.create_project(
    name=f'my-build-{suffix}',
    description='Test CodeBuild project',
    source={
        'type': 'NO_SOURCE',
        'buildspec':'version: 0.2\nphases:\n  build:\n    commands:\n      - echo Hello, World!'
    },
    artifacts={
        'type': 'NO_ARTIFACTS'
    },
    environment={
        'type': 'LINUX_CONTAINER',
        'image': 'aws/codebuild/standard:7.0',
        'computeType': 'BUILD_GENERAL1_SMALL'
    },
    serviceRole=ROLE_ARN,
    tags=[{'key':'project','value':'doc-smith'},{'key':'tutorial','value':'codebuild-gs'}]
)

print("Starting build...")
build = client.start_build(
    projectName=f'my-build-{suffix}'
)
build_id = build['build']['id']

print("Waiting for build to complete...")
for _ in range(20):
    time.sleep(5)
    b = client.batch_get_builds(ids=[build_id])
    if b['builds'][0]['buildStatus']!= 'IN_PROGRESS': 
        break

print("Deleting project...")
client.delete_project(name=f'my-build-{suffix}')

print("PASS")