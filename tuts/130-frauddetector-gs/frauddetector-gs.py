import boto3
import json
import time
import os
import uuid
import random

ROLE_ARN = os.environ.get('TUTORIAL_ROLE_ARN')
if ROLE_ARN:
    session = boto3.Session()
    client = session.client('frauddetector', region_name='us-east-1')
else:
    client = boto3.client('frauddetector', region_name='us-east-1')

suffix = ''.join(random.choices('abcdefghijklmnopqrstuvwxyz0123456789', k=6))
variable_name = f'var_{suffix}'
detector_id = f'det_{suffix}'
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'frauddetector-gs'}]

# Step 1: Create a fraud detection variable
print("Step 1: Creating a variable to be used in the detector.")
create_variable_response = client.create_variable(
    name=variable_name,
    dataType='STRING',
    dataSource='EVENT',
    defaultValue='UNKNOWN',
    description='Test variable for fraud detection',
    tags=tags
)
print(f"Variable {variable_name} created:", json.dumps(create_variable_response, indent=2))

# Step 2: Create Detector
print("Step 2: Creating a detector to evaluate fraud.")
client.put_detector(
    detectorId=detector_id,
    description='Sample detector for tutorial',
    eventType='sample_event',
    tags=tags
)
print(f"Detector {detector_id} created.")

# Step 3: Create Detector Version
print("Step 3: Creating a version of the detector to define its rules and models.")
detector_version_id = '1.0'
client.create_detector_version(
    detectorId=detector_id,
    description='Sample detector version for tutorial',
    rules=[{
        'detectorId': detector_id,
        'ruleId': f'rule_{suffix}',
        'ruleVersion': '1.0',
        'expression':'sample_expression',
        'language': 'DETECTORPL',
        'outcomes': ['outcome_1']
    }],
    modelVersions=[],
    externalModelEndpoints=[],
    tags=tags
)
print(f"Detector version {detector_version_id} created for {detector_id}.")

# Step 4: Verify Detector Version
print("Step 4: Verifying the detector version exists.")
time.sleep(10)  # Wait for the detector version to become active
response = client.describe_detector(detectorId=detector_id)
print(f"Detector {detector_id} version {detector_version_id} verified:", json.dumps(response, indent=2))

# Clean up
print("Cleaning up resources.")
client.delete_detector_version(detectorId=detector_id, detectorVersionId=detector_version_id)
print(f"Deleted detector version {detector_version_id} for {detector_id}.")
client.delete_detector(detectorId=detector_id)
print(f"Deleted detector {detector_id}.")
delete_variable_response = client.delete_variable(name=variable_name)
print(f"Deleted variable {variable_name}:", json.dumps(delete_variable_response, indent=2))

print("PASS")