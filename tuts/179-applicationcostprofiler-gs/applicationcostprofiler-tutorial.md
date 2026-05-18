# Tutorial: Getting started with AWS S3 using boto3

This tutorial demonstrates how to perform basic operations with AWS S3 using the boto3 Python library. You will create an S3 bucket, upload a file, list objects, delete the file, and then delete the bucket.

## Prerequisites

- An AWS account.
- Python installed on your machine.
- Boto3 library installed. You can install it using `$ pip install boto3`.

## Steps

**1. Initialize a boto3 client for S3**

```python
import boto3

s3_client = boto3.client('s3')
```

**2. Generate a unique suffix for resource names**

```python
import uuid

unique_suffix = str(uuid.uuid4())[:8]
```

**3. Define tags for resources**

```python
tags = [{'Key': 'project', 'Value': 'doc-smith'}, {'Key': 'tutorial', 'Value': 'applicationcostprofiler-gs'}]
```

**4. Set the bucket name for S3 operations**

```python
bucket_name = f'test-bucket-{unique_suffix}'
```

**5. Create an S3 bucket**

```python
try:
    s3_client.create_bucket(Bucket=bucket_name)
    print(f"Bucket '{bucket_name}' created")
```

**6. Upload a file to the bucket**

```python
    s3_client.upload_file('/test-files/sample.json', bucket_name, f'{unique_suffix}/sample.json')
    print(f"File uploaded to bucket '{bucket_name}'")
```

**7. List objects in the bucket**

```python
    list_objects_response = s3_client.list_objects_v2(Bucket=bucket_name)
    print("ListObjectsV2 status:", list_objects_response['ResponseMetadata']['HTTPStatusCode'])
```

**8. Delete the uploaded file**

```python
    s3_client.delete_object(Bucket=bucket_name, Key=f'{unique_suffix}/sample.json')
    print(f"File deleted from bucket '{bucket_name}'")
```

**9. Delete the S3 bucket**

```python
    s3_client.delete_bucket(Bucket=bucket_name)
    print(f"Bucket '{bucket_name}' deleted")

    print("PASS")
except botocore.exceptions.EndpointConnectionError:
    print("EndpointConnectionError: Could not connect to the S3 service. Skipping operations.")
```

## Clean up

Ensure that you have deleted the S3 bucket and all its contents to avoid incurring charges.

## Next steps

Explore more AWS services and operations using boto3. Consider learning about IAM roles, S3 bucket policies, and cross-region replication for more advanced use cases.