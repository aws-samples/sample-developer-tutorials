# Serverless Application Repository Tutorial

## Prerequisites

- Python installed on your machine
- AWS CLI configured with appropriate permissions
- Boto3 python library installed

## Steps

**1. Create Application**

```bash
$ python -c 'import boto3; import time; client = boto3.client('serverlessrepo', region_name='us-east-1'); suffix = str(int(time.time()))[-6:]; response = client.create_application(Author='doc-smith', Description='Sample application for serverlessrepo tutorial', Name=f'doc-smith-app-{suffix}', Labels=['project:doc-smith', 'tutorial:serverlessrepo-gs']); print(f"Application created: {response['ApplicationId']}")'
```

**2. Verify Application**

```bash
$ python -c 'import boto3; application_id = "<application_id>"; client = boto3.client('serverlessrepo', region_name='us-east-1'); response = client.get_application(ApplicationId=application_id); print(f"Application verified: {response['Name']}")'
```

**3. Create CloudFormation Template**

```python
import json
import time

suffix = str(int(time.time()))[-6:]
template_body = json.dumps({
    "Transform": "AWS::Serverless-2016-10-31",
    "Resources": {
        "SampleResource": {
            "Type": "AWS::S3::Bucket",
            "Properties": {
                "BucketName": f"doc-smith-bucket-{suffix}"
            }
        }
    }
})
```

**4. Create Application Version with Template Specification**

```bash
$ python -c 'import boto3; import json; application_id = "<application_id>"; suffix = str(int(time.time()))[-6:]; client = boto3.client('serverlessrepo', region_name='us-east-1'); template_body = json.dumps({"Transform": "AWS::Serverless-2016-10-31", "Resources": {"SampleResource": {"Type": "AWS::S3::Bucket", "Properties": {"BucketName": f"doc-smith-bucket-{suffix}"}} }}); version = f"1.0.{suffix}"; response = client.create_application_version(ApplicationId=application_id, SemanticVersion=version, TemplateBody=template_body); print(f"Application version created: {version}")'
```

## Clean up

**Delete Application**

```bash
$ python -c 'import boto3; application_id = "<application_id>"; client = boto3.client('serverlessrepo', region_name='us-east-1'); try: client.delete_application(ApplicationId=application_id); print(f"Application deleted: {application_id}"); except Exception as e: print(f"Failed to delete application: {e}");'
```

## Next steps

- Explore more AWS Serverless Application Repository features
- Deploy the created application to your AWS account