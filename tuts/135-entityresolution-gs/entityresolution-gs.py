import boto3
import json
import time
import os
import uuid

# Initialize boto3 client
client = boto3.client('entityresolution', region_name='us-east-1')

# Generate a unique suffix
suffix = str(int(time.time()))[-6:]
schema_name = f"test-schema-{suffix}"
idempotency_token = uuid.uuid4().hex[:8]

tags = {
    'project': 'doc-smith',
    'tutorial': 'entityresolution-gs'
}

# Create Schema Mapping
print("Creating a Schema Mapping...")
mapped_input_fields = [
    {
        'fieldName': 'uniqueId',
        'type':'UNIQUE_ID'
    },
    {
        'fieldName': 'firstName',
        'type':'NAME_FIRST'
    },
    {
        'fieldName': 'lastName',
        'type':'NAME_LAST'
    },
    {
        'fieldName': 'email',
        'type':'EMAIL_ADDRESS'
    }
]
response = client.create_schema_mapping(
    schemaName=schema_name,
    description="Test schema for entity resolution",
    mappedInputFields=mapped_input_fields,
    tags=tags
)
print(f"Schema Mapping created with name: {schema_name}")

# Verify Schema Mapping
print("Verifying created Schema Mapping...")
get_schema_response = client.get_schema_mapping(schemaName=schema_name)
print("Schema Mapping verified successfully:", get_schema_response)

# Create a Matching Workflow
print("Creating a Matching Workflow...")
workflow_name = f"MatchingWorkflow-{suffix}"
input_source_config = [
    {
        "inputSourceARN": "arn:aws:entityresolution:us-east-1:123456789012:inputsource/example",
        "schemaName": schema_name
    }
]
output_source_config = [
    {
        "outputS3Path": "s3://example-bucket/output/",
        "kmsKeyId": "arn:aws:kms:us-east-1:123456789012:key/example-key-id"
    }
]
resolution_techniques = {
    "resolutionType": "RULE_MATCHING",
    "ruleBasedProperties": {
        "attributeMatchingModel": "ONE_TO_ONE"
    }
}
role_arn = os.environ.get('TUTORIAL_ROLE_ARN')
if role_arn:
    response = client.create_matching_workflow(
        workflowName=workflow_name,
        inputSourceConfig=input_source_config,
        outputSourceConfig=output_source_config,
        resolutionTechniques=resolution_techniques,
        roleArn=role_arn
    )
    print(f"Matching Workflow created with name: {workflow_name}")

# Verify the created resources
print("Verifying created resources...")
get_schema_response = client.get_schema_mapping(schemaName=schema_name)
print("Schema Mapping verified successfully:", get_schema_response)
if role_arn:
    get_workflow_response = client.get_matching_workflow(workflowName=workflow_name)
    print("Matching Workflow verified successfully:", get_workflow_response)

# Clean up created resources
print("Cleaning up resources...")
if role_arn:
    client.delete_matching_workflow(workflowName=workflow_name)
client.delete_schema_mapping(schemaName=schema_name)
print("Resources cleaned up.")