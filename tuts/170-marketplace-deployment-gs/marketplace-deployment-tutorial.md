# Tutorial: Managing AWS Marketplace Deployment Resources

This tutorial demonstrates how to manage resources in AWS Marketplace Deployment using the AWS SDK for Python (Boto3). You will learn how to list tags for a resource, put a deployment parameter, tag a resource, list tags for the tagged resource, and untag a resource.

## Prerequisites

- An AWS account.
- AWS CLI configured with your credentials.
- Python installed on your machine.
- Boto3 library installed (`$ pip install boto3`).

## Steps

### 1. List tags for a resource

**Code block: ListTagsForResource**

```python
response = client.list_tags_for_resource(ResourceArn='arn:aws:marketplace-deployment:us-east-1:123456789012:resource/example')
print(response)
```

**Output:**

```json
{
    "Tags": [
        {
            "Key": "example-key",
            "Value": "example-value"
        }
    ]
}
```

### 2. Put a deployment parameter

**Code block: PutDeploymentParameter**

```python
response = client.put_deployment_parameter(
    ResourceArn='arn:aws:marketplace-deployment:us-east-1:123456789012:resource/example',
    ParameterName='example-param',
    ParameterValue='example-value'
)
print(response)
```

**Output:**

```json
{
    "ResponseMetadata": {
        "HTTPStatusCode": 200
    }
}
```

### 3. Tag a resource

**Code block: TagResource**

```python
resource_arn = f'arn:aws:marketplace-deployment:us-east-1:123456789012:resource/example-{suffix}'
client.tag_resource(
    ResourceArn=resource_arn,
    Tags=[{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value':'marketplace-deployment-gs'}]
)
```

### 4. List tags for the tagged resource

**Code block: ListTagsForTaggedResource**

```python
response = client.list_tags_for_resource(ResourceArn=resource_arn)
print(response)
```

**Output:**

```json
{
    "Tags": [
        {
            "Key": "project",
            "Value": "doc-smith"
        },
        {
            "Key": "tutorial",
            "Value": "marketplace-deployment-gs"
        }
    ]
}
```

### 5. Untag a resource

**Code block: UntagResource**

```python
client.untag_resource(
    ResourceArn=resource_arn,
    TagKeys=['project', 'tutorial']
)
```

## Clean up

To avoid unnecessary charges, clean up the resources you created for this tutorial.

**Code block: Cleanup**

```python
try:
    print("Cleaning up created resources...")
    # Add cleanup logic if necessary
except Exception as e:
    print(f"Cleanup error: {e}")
```

## Next steps

- Explore more AWS Marketplace Deployment features.
- Learn about tagging strategies for better resource management.
- Check out the [Boto3 documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html) for more AWS service interactions.