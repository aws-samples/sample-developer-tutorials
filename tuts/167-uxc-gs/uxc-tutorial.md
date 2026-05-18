# Tutorial: Interacting with Amazon S3 using Boto3

## Prerequisites

- An aws account.
- Python installed on your machine.
- Boto3 library installed (`$ pip install boto3`).
- Aws credentials (access key id and secret access key).

## Steps

### 1. Initialize a session using amazon s3

```python
import boto3
import uuid

# Initialize a session using amazon s3
session = boto3.Session(
    aws_access_key_id='your_access_key',
    aws_secret_access_key='your_secret_key',
    region_name='us-west-2'  # Change to your preferred region
)

s3_client = session.client('s3')
```

### 2. Generate a unique suffix

```python
# Generate a unique suffix
unique_suffix = str(uuid.uuid4())[:8]
```

### 3. List s3 buckets

```python
# List s3 buckets (commented out due to invalidaccesskeyid error)
# response = s3_client.list_buckets()
# print("listbuckets status:", response['responsemetadata']['httpstatuscode'])
```

### 4. Create a new s3 bucket

```python
# Create a new s3 bucket (example action to demonstrate functionality)
bucket_name = f'my-test-bucket-{unique_suffix}'
try:
    s3_client.create_bucket(bucket=bucket_name)
    print("bucket creation status: success")
except exception as e:
    print("bucket creation status: failure", str(e))
```

## Clean up

### 1. Delete the created bucket

```python
# Clean up: delete the created bucket
try:
    s3_client.delete_bucket(bucket=bucket_name)
    print("bucket deletion status: success")
except exception as e:
    print("bucket deletion status: failure", str(e))
```

## Next steps

- Explore more amazon s3 operations using boto3.
- Implement error handling for production-ready code.
- Securely manage your aws credentials.