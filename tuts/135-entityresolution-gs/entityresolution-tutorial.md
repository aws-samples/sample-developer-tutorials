# Getting started with AWS Entity Resolution

## Prerequisites

Before you begin, ensure you have the following:

- AWS CLI installed and configured
- Necessary IAM permissions
- A CloudFormation stack with required roles if needed

## Step 1: Create a Schema Mapping

**Before running the script, ensure you have the necessary IAM permissions to create a schema mapping.**

**Python Script:**
```python
import boto3
import json
import time

# Initialize boto3 client
client = boto3.client('entityresolution')

# Generate a unique suffix
suffix = str(int(time.time()))[-6:]

# Create a Schema Mapping
print("Creating a Schema Mapping...")
schema_name = f"SchemaMapping-{suffix}"
mapped_input_fields = [
    {
        "name": "fieldName1",
        "type": "string",
        "groupName": "group1"
    },
    {
        "name": "fieldName2",
        "type": "string",
        "groupName": "group1"
    }
]
response = client.create_schema_mapping(
    schemaName=schema_name,
    mappedInputFields=mapped_input_fields
)
print(f"Schema Mapping created with name: {schema_name}")
```

**CLI Command:**
```bash
$ aws entityresolution create-schema-mapping --schema-name "test-schema-$SUFFIX" --mapped-input-fields '[{"fieldName":"id","type":"UNIQUE_ID"},{"fieldName":"name","type":"NAME"}]'
```

**After running the script, you should see the output indicating the schema mapping has been created.**

## Step 2: Create an ID Namespace

**Before running the script, ensure you have the necessary IAM permissions to create an ID namespace.**

**Python Script:**
```python
# Create an ID Namespace
print("Creating an ID Namespace...")
id_namespace_name = f"IDNamespace-{suffix}"
response = client.create_id_namespace(
    idNamespaceName=id_namespace_name,
    type="CUSTOMER"
)
print(f"ID Namespace created with name: {id_namespace_name}")
```

**CLI Command:**
```bash
$ aws entityresolution create-id-namespace --id-namespace-name "test-id-namespace-$SUFFIX" --type "CUSTOMER"
```

**After running the script, you should see the output indicating the ID namespace has been created.**

## Step 3: Create a Matching Workflow

**Before running the script, ensure you have the necessary IAM permissions to create a matching workflow.**

**Python Script:**
```python
# Create a Matching Workflow
print("Creating a Matching Workflow...")
workflow_name = f"MatchingWorkflow-{suffix}"
input_source_config = [
    {
        "inputSourceARN": "arn:aws:entityresolution:us-west-2:123456789012:inputsource/example",
        "schemaName": schema_name
    }
]
output_source_config = [
    {
        "outputS3Path": "s3://example-bucket/output/",
        "kmsKeyId": "arn:aws:kms:us-west-2:123456789012:key/example-key-id"
    }
]
resolution_techniques = {
    "resolutionType": "RULE_MATCHING",
    "ruleBasedProperties": {
        "attributeMatchingModel": "ONE_TO_ONE"
    }
}
role_arn = os.environ.get('TUTORIAL_ROLE_ARN')
response = client.create_matching_workflow(
    workflowName=workflow_name,
    inputSourceConfig=input_source_config,
    outputSourceConfig=output_source_config,
    resolutionTechniques=resolution_techniques,
    roleArn=role_arn
)
print(f"Matching Workflow created with name: {workflow_name}")
```

**CLI Command:**
```bash
$ aws entityresolution create-matching-workflow --workflow-name "test-workflow-$SUFFIX" --input-source-config '[{"inputSourceARN":"arn:aws:entityresolution:us-west-2:123456789012:inputsource/example","schemaName":"test-schema-$SUFFIX"}]' --output-source-config '[{"outputS3Path":"s3://example-bucket/output/","kmsKeyId":"arn:aws:kms:us-west-2:123456789012:key/example-key-id"}]' --resolution-techniques '{"resolutionType":"RULE_MATCHING","ruleBasedProperties":{"attributeMatchingModel":"ONE_TO_ONE"}}' --role-arn "arn:aws:iam::123456789012:role/example-role"
```

**After running the script, you should see the output indicating the matching workflow has been created.**

## Step 4: Verify Created Resources

**Python Script:**
```python
# Verify the created resources
print("Verifying created resources...")
get_schema_response = client.get_schema_mapping(schemaName=schema_name)
get_id_namespace_response = client.get_id_namespace(idNamespaceName=id_namespace_name)
get_workflow_response = client.get_matching_workflow(workflowName=workflow_name)
print("Resources verified successfully.")
```

**CLI Command:**
```bash
$ aws entityresolution get-schema-mapping --schema-name "test-schema-$SUFFIX"
$ aws entityresolution get-id-namespace --id-namespace-name "test-id-namespace-$SUFFIX"
$ aws entityresolution get-matching-workflow --workflow-name "test-workflow-$SUFFIX"
```

**After running the verification commands, you should see the output indicating the resources have been successfully created and retrieved.**

## Clean up

To avoid unnecessary charges, clean up the resources you created.

**Python Script:**
```python
# Clean up created resources
print("Cleaning up resources...")
client.delete_matching_workflow(workflowName=workflow_name)
client.delete_id_namespace(idNamespaceName=id_namespace_name)
client.delete_schema_mapping(schemaName=schema_name)
print("Resources cleaned up successfully.")
```

**CLI Command:**
```bash
$ aws entityresolution delete-matching-workflow --workflow-name "test-workflow-$SUFFIX"
$ aws entityresolution delete-id-namespace --id-namespace-name "test-id-namespace-$SUFFIX"
$ aws entityresolution delete-schema-mapping --schema-name "test-schema-$SUFFIX"
```

**After running the cleanup commands, you should see the output indicating the resources have been successfully deleted.**

## Next steps

- Explore different resolution techniques and configurations.
- Integrate AWS Entity Resolution with your data pipelines.
- Monitor and optimize your matching workflows for better performance.
