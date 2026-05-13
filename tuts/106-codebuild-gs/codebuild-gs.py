import boto3
import time

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
    serviceRole='arn:aws:iam::559823168634:role/doc-babu-codebuild-role'
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