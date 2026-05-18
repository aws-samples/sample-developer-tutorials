# Bedrock Data Automation Runtime Tutorial

## Prerequisites

- An aws account.
- Aws cli configured with appropriate permissions.
- Python installed with boto3 library.

## Steps

**1. List tags for a resource**

```bash
$ python -c 'import boto3; client = boto3.client("bedrock-data-automation-runtime", region_name="us-east-1"); response = client.list_tags_for_resource(ResourceArn="arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example"); print(response)'
```

**2. Get data automation status**

```bash
$ python -c 'import boto3; client = boto3.client("bedrock-data-automation-runtime", region_name="us-east-1"); response = client.get_data_automation_status(AutomationId="example-automation-id"); print(response)'
```

**3. Invoke data automation**

```bash
$ python -c 'import boto3; client = boto3.client("bedrock-data-automation-runtime", region_name="us-east-1"); response = client.invoke_data_automation(AutomationId="example-automation-id", InputParameters=\'{"key": "value"}\'); print(response)'
```

**4. Tag a resource**

```bash
$ python -c 'import boto3; client = boto3.client("bedrock-data-automation-runtime", region_name="us-east-1"); response = client.tag_resource(ResourceArn="arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example", Tags=[{"Key":"project","Value":"doc-smith"},{"Key":"tutorial","Value":"bedrock-data-automation-runtime-gs"}]); print(response)'
```

**5. Untag a resource**

```bash
$ python -c 'import boto3; client = boto3.client("bedrock-data-automation-runtime", region_name="us-east-1"); response = client.untag_resource(ResourceArn="arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example", TagKeys=["project", "tutorial"]); print(response)'
```

## Clean up

To ensure no unnecessary resources are left, run the following command to untag the resource.

```bash
$ python -c 'import boto3; client = boto3.client("bedrock-data-automation-runtime", region_name="us-east-1"); try: response = client.untag_resource(ResourceArn="arn:aws:bedrock-data-automation-runtime:us-east-1:123456789012:resource/example", TagKeys=["project", "tutorial"]); print(response) except: pass'
```

## Next steps

Explore more about aws bedrock data automation runtime and its capabilities.